// Cassowary constraint solver (kiwi-style incremental simplex).
// Owner: autolayout module (M9).
//
// Pure Swift, no dependencies. Solves systems of linear equality/inequality
// constraints over real variables, minimizing the weighted violation of
// non-required ("optional") constraints. This is the engine underneath
// NSLayoutConstraint (LayoutEngine.swift maps UIKit attributes onto
// variables and UIKit priorities 1...999 onto objective weights; priority
// 1000 constraints are added as required/hard).
//
// Semantics notes (deliberate, matching what the M9 fixtures exercise):
// - Optional-constraint violation is minimized as a WEIGHTED SUM
//   (weight = strength). For the pairwise priority battles UIKit layouts are
//   built from (750 vs 749, 251 vs 250, 999 vs required, ...) the LP optimum
//   is winner-take-all: the higher-priority constraint is satisfied exactly.
//   A strict lexicographic hierarchy (where no number of priority-250
//   constraints can outweigh one 251) is NOT implemented; fixtures and
//   normal UIKit layouts do not depend on it.
// - Deterministic pivoting: entering/leaving choices tie-break on symbol id,
//   so identical systems always solve to identical vertices.
//
// Correctness over speed: rows are small dictionaries; scenes have tens of
// variables. The solver is incremental (add/remove constraint + re-optimize)
// even though the layout engine currently rebuilds per solve.

public enum Cassowary {

    // MARK: - Public model

    public final class Variable: Hashable {
        public let name: String
        public init(_ name: String = "") { self.name = name }
        public static func == (a: Variable, b: Variable) -> Bool { a === b }
        public func hash(into h: inout Hasher) { h.combine(ObjectIdentifier(self)) }
    }

    public struct Term {
        public var variable: Variable
        public var coefficient: Double
        public init(_ variable: Variable, _ coefficient: Double = 1) {
            self.variable = variable
            self.coefficient = coefficient
        }
    }

    /// Linear expression: sum(coefficient * variable) + constant.
    public struct Expression {
        public var terms: [Term]
        public var constant: Double
        public init(terms: [Term] = [], constant: Double = 0) {
            self.terms = terms
            self.constant = constant
        }
        public init(_ variable: Variable, coefficient: Double = 1, constant: Double = 0) {
            self.terms = [Term(variable, coefficient)]
            self.constant = constant
        }
        public mutating func add(_ variable: Variable, _ coefficient: Double) {
            terms.append(Term(variable, coefficient))
        }
        public mutating func add(_ other: Expression, multiplier: Double = 1) {
            constant += other.constant * multiplier
            for t in other.terms {
                terms.append(Term(t.variable, t.coefficient * multiplier))
            }
        }
    }

    public enum Relation: Sendable {
        case lessThanOrEqual, equal, greaterThanOrEqual
    }

    /// Strength of a required (hard) constraint. Anything >= this is hard;
    /// everything below is minimized-violation with weight = strength.
    public static let requiredStrength: Double = 1e9

    public final class Constraint: Hashable {
        /// Canonical form: expression (relation) 0.
        public let expression: Expression
        public let relation: Relation
        public let strength: Double
        public init(_ expression: Expression, _ relation: Relation,
                    strength: Double = Cassowary.requiredStrength) {
            self.expression = expression
            self.relation = relation
            self.strength = strength
        }
        public var isRequired: Bool { strength >= Cassowary.requiredStrength }
        public static func == (a: Constraint, b: Constraint) -> Bool { a === b }
        public func hash(into h: inout Hasher) { h.combine(ObjectIdentifier(self)) }
    }

    public enum SolverError: Error {
        case unsatisfiableConstraint
        case duplicateConstraint
        case unknownConstraint
        case internalError(String)
    }

    // MARK: - Solver internals

    struct Symbol: Hashable, Comparable {
        enum Kind: UInt8 { case invalid, external, slack, error, dummy }
        var kind: Kind
        var id: Int
        static let invalid = Symbol(kind: .invalid, id: 0)
        var isPivotable: Bool { kind == .slack || kind == .error }
        static func < (a: Symbol, b: Symbol) -> Bool { a.id < b.id }
    }

    final class Row {
        var constant: Double
        var cells: [Symbol: Double] = [:]

        init(constant: Double = 0) { self.constant = constant }
        init(copying other: Row) {
            constant = other.constant
            cells = other.cells
        }

        func insert(_ symbol: Symbol, _ coefficient: Double = 1) {
            let v = (cells[symbol] ?? 0) + coefficient
            if nearZero(v) { cells[symbol] = nil } else { cells[symbol] = v }
        }

        func insert(_ row: Row, _ coefficient: Double) {
            constant += row.constant * coefficient
            for (s, c) in row.cells { insert(s, c * coefficient) }
        }

        func remove(_ symbol: Symbol) { cells[symbol] = nil }

        func reverseSign() {
            constant = -constant
            for (s, c) in cells { cells[s] = -c }
        }

        /// Row is `basis = constant + cells`; make `symbol` (present with
        /// nonzero coefficient) the subject: symbol = ...
        func solveFor(_ symbol: Symbol) {
            let coeff = -1.0 / (cells[symbol] ?? 0)
            cells[symbol] = nil
            constant *= coeff
            for (s, c) in cells { cells[s] = c * coeff }
        }

        /// Given `lhs = rhs-row`, rewrite as `rhs = ...` where rhs appears
        /// in this row.
        func solveFor(_ lhs: Symbol, _ rhs: Symbol) {
            insert(lhs, -1)
            solveFor(rhs)
        }

        func coefficient(for symbol: Symbol) -> Double { cells[symbol] ?? 0 }

        /// Replace `symbol` in this row with `row` (its definition).
        func substitute(_ symbol: Symbol, _ row: Row) {
            guard let coeff = cells[symbol] else { return }
            cells[symbol] = nil
            insert(row, coeff)
        }
    }

    struct Tag {
        var marker: Symbol
        var other: Symbol
    }

    static func nearZero(_ v: Double) -> Bool { abs(v) < 1e-8 }

    public final class Solver {
        var rows: [Symbol: Row] = [:]
        var varSymbols: [Variable: Symbol] = [:]
        var tags: [Constraint: Tag] = [:]
        let objective = Row()
        var nextSymbolID = 1

        public init() {}

        public var constraintCount: Int { tags.count }

        public func hasConstraint(_ c: Constraint) -> Bool { tags[c] != nil }

        func makeSymbol(_ kind: Symbol.Kind) -> Symbol {
            defer { nextSymbolID += 1 }
            return Symbol(kind: kind, id: nextSymbolID)
        }

        func symbol(for v: Variable) -> Symbol {
            if let s = varSymbols[v] { return s }
            let s = makeSymbol(.external)
            varSymbols[v] = s
            return s
        }

        /// Current solved value of a variable (0 when unconstrained).
        public func value(of v: Variable) -> Double {
            guard let s = varSymbols[v] else { return 0 }
            return rows[s]?.constant ?? 0
        }

        // MARK: Add

        public func addConstraint(_ c: Constraint) throws {
            guard tags[c] == nil else { throw SolverError.duplicateConstraint }

            var tag = Tag(marker: .invalid, other: .invalid)
            let row = createRow(c, &tag)
            var subject = chooseSubject(row, tag)

            if subject.kind == .invalid && allDummies(row) {
                if !Cassowary.nearZero(row.constant) {
                    throw SolverError.unsatisfiableConstraint
                }
                subject = tag.marker
            }

            if subject.kind == .invalid {
                if !(try addWithArtificialVariable(row)) {
                    throw SolverError.unsatisfiableConstraint
                }
            } else {
                row.solveFor(subject)
                substituteOut(subject, row)
                rows[subject] = row
            }

            tags[c] = tag
            try optimize(objective)
        }

        // MARK: Remove

        public func removeConstraint(_ c: Constraint) throws {
            guard let tag = tags.removeValue(forKey: c) else {
                throw SolverError.unknownConstraint
            }
            // Remove the error effects from the objective (before the marker
            // row is potentially pivoted away).
            removeConstraintEffects(c, tag)

            if rows.removeValue(forKey: tag.marker) == nil {
                // Marker is not basic: pivot it into some row containing it,
                // then drop that row (the marker only occurs in this
                // constraint, so substituting its definition removes it from
                // the whole tableau).
                guard let (leaving, row) = markerLeavingRow(tag.marker) else {
                    throw SolverError.internalError("failed to find leaving row")
                }
                rows[leaving] = nil
                row.solveFor(leaving, tag.marker)
                substituteOut(tag.marker, row)
            }
            try optimize(objective)
        }

        private func removeConstraintEffects(_ c: Constraint, _ tag: Tag) {
            if tag.marker.kind == .error { removeMarkerEffects(tag.marker, c.strength) }
            if tag.other.kind == .error { removeMarkerEffects(tag.other, c.strength) }
        }

        private func removeMarkerEffects(_ marker: Symbol, _ strength: Double) {
            if let row = rows[marker] {
                objective.insert(row, -strength)
            } else {
                objective.insert(marker, -strength)
            }
        }

        private func markerLeavingRow(_ marker: Symbol) -> (Symbol, Row)? {
            var ratio1 = Double.greatestFiniteMagnitude
            var ratio2 = Double.greatestFiniteMagnitude
            var first: (Symbol, Row)? = nil
            var second: (Symbol, Row)? = nil
            var third: (Symbol, Row)? = nil
            for (sym, row) in rows.sorted(by: { $0.key < $1.key }) {
                let c = row.coefficient(for: marker)
                if c == 0 { continue }
                if sym.kind == .external {
                    third = (sym, row)
                } else if c < 0 {
                    let r = -row.constant / c
                    if r < ratio1 { ratio1 = r; first = (sym, row) }
                } else {
                    let r = row.constant / c
                    if r < ratio2 { ratio2 = r; second = (sym, row) }
                }
            }
            return first ?? second ?? third
        }

        // MARK: Tableau construction

        private func createRow(_ c: Constraint, _ tag: inout Tag) -> Row {
            let expr = c.expression
            let row = Row(constant: expr.constant)
            // Substitute basic variables by their rows.
            var merged: [Symbol: Double] = [:]
            for t in expr.terms {
                if Cassowary.nearZero(t.coefficient) { continue }
                let s = symbol(for: t.variable)
                merged[s, default: 0] += t.coefficient
            }
            for (s, coeff) in merged.sorted(by: { $0.key < $1.key }) {
                if Cassowary.nearZero(coeff) { continue }
                if let basic = rows[s] {
                    row.insert(basic, coeff)
                } else {
                    row.insert(s, coeff)
                }
            }

            switch c.relation {
            case .lessThanOrEqual, .greaterThanOrEqual:
                let coeff: Double = c.relation == .lessThanOrEqual ? 1 : -1
                let slack = makeSymbol(.slack)
                tag.marker = slack
                row.insert(slack, coeff)
                if !c.isRequired {
                    let error = makeSymbol(.error)
                    tag.other = error
                    row.insert(error, -coeff)
                    objective.insert(error, c.strength)
                }
            case .equal:
                if !c.isRequired {
                    let errplus = makeSymbol(.error)
                    let errminus = makeSymbol(.error)
                    tag.marker = errplus
                    tag.other = errminus
                    row.insert(errplus, -1)   // v = eplus - eminus
                    row.insert(errminus, 1)
                    objective.insert(errplus, c.strength)
                    objective.insert(errminus, c.strength)
                } else {
                    let dummy = makeSymbol(.dummy)
                    tag.marker = dummy
                    row.insert(dummy, 1)
                }
            }

            if row.constant < 0 { row.reverseSign() }
            return row
        }

        private func chooseSubject(_ row: Row, _ tag: Tag) -> Symbol {
            // Prefer an external variable (deterministic: lowest id).
            var best: Symbol? = nil
            for (s, _) in row.cells where s.kind == .external {
                if best == nil || s < best! { best = s }
            }
            if let b = best { return b }
            if tag.marker.isPivotable, row.coefficient(for: tag.marker) < 0 {
                return tag.marker
            }
            if tag.other.isPivotable, row.coefficient(for: tag.other) < 0 {
                return tag.other
            }
            return .invalid
        }

        private func allDummies(_ row: Row) -> Bool {
            for (s, _) in row.cells where s.kind != .dummy { return false }
            return true
        }

        private func addWithArtificialVariable(_ row: Row) throws -> Bool {
            let art = makeSymbol(.slack)
            rows[art] = Row(copying: row)
            // Kept as a member so substituteOut updates it during pivoting.
            artificial = Row(copying: row)
            try optimize(artificial!)
            let success = Cassowary.nearZero(artificial!.constant)
            artificial = nil

            if let artRow = rows.removeValue(forKey: art) {
                if artRow.cells.isEmpty { return success }
                var entering = Symbol.invalid
                for (s, _) in artRow.cells.sorted(by: { $0.key < $1.key })
                where s.isPivotable {
                    entering = s
                    break
                }
                if entering.kind == .invalid { return false }
                artRow.solveFor(art, entering)
                substituteOut(entering, artRow)
                rows[entering] = artRow
            }
            for (_, r) in rows { r.remove(art) }
            objective.remove(art)
            return success
        }

        /// In-flight artificial objective (addWithArtificialVariable); kept
        /// as a member so pivot substitutions reach it.
        private var artificial: Row?

        private func substituteOut(_ symbol: Symbol, _ row: Row) {
            for (_, r) in rows { r.substitute(symbol, row) }
            objective.substitute(symbol, row)
            artificial?.substitute(symbol, row)
        }

        // MARK: Simplex optimization

        private func optimize(_ objective: Row) throws {
            var iterations = 0
            while true {
                iterations += 1
                if iterations > 100_000 {
                    throw SolverError.internalError("simplex did not converge")
                }
                // Entering: any non-dummy symbol with a negative objective
                // coefficient (deterministic: lowest id).
                var entering = Symbol.invalid
                for (s, c) in objective.cells.sorted(by: { $0.key < $1.key })
                where s.kind != .dummy && c < 0 {
                    entering = s
                    break
                }
                if entering.kind == .invalid { return }

                // Leaving: restricted (non-external) basic row with the
                // minimum ratio (deterministic tie-break: lowest id).
                var minRatio = Double.greatestFiniteMagnitude
                var leaving = Symbol.invalid
                var leavingRow: Row? = nil
                for (s, r) in rows.sorted(by: { $0.key < $1.key })
                where s.kind != .external {
                    let c = r.coefficient(for: entering)
                    if c < 0 {
                        let ratio = -r.constant / c
                        if ratio < minRatio {
                            minRatio = ratio
                            leaving = s
                            leavingRow = r
                        }
                    }
                }
                guard let row = leavingRow else {
                    // Unbounded objective: can happen transiently for
                    // artificial objectives; treat as internal error.
                    throw SolverError.internalError("objective is unbounded")
                }
                rows[leaving] = nil
                row.solveFor(leaving, entering)
                substituteOut(entering, row)
                rows[entering] = row
            }
        }
    }
}
