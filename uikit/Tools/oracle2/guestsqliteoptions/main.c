/* The platform libsqlite3's identity and its build: version, threading mode,
 * every compile option, and the pragma defaults that valueless options such as
 * DEFAULT_AUTOVACUUM leave unstated. Same file on the simulator and the guest. */
#include <sqlite3.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static int print_row(void *label, int n, char **values, char **names) {
  (void)n; (void)names;
  printf("pragma %s %s %s\n", (const char *)label, names[0], values[0] ? values[0] : "NULL");
  return 0;
}

static void pragmas(const char *label, const char *path) {
  sqlite3 *db = NULL;
  if (sqlite3_open(path, &db) != SQLITE_OK) { printf("open %s failed\n", label); return; }
  const char *names[] = {"auto_vacuum", "recursive_triggers", "page_size", "cache_size",
                         "synchronous", "journal_mode", "temp_store", "foreign_keys",
                         "journal_size_limit", "mmap_size", "wal_autocheckpoint", "encoding"};
  for (size_t i = 0; i < sizeof names / sizeof names[0]; i++) {
    char sql[64];
    snprintf(sql, sizeof sql, "PRAGMA %s", names[i]);
    if (sqlite3_exec(db, sql, print_row, (void *)label, NULL) != SQLITE_OK)
      printf("pragma %s %s error %s\n", label, names[i], sqlite3_errmsg(db));
  }
  sqlite3_close(db);
}

static int print_result(void *label, int n, char **values, char **names) {
  printf("%s", (const char *)label);
  for (int i = 0; i < n; i++) printf(" %s=%s", names[i], values[i] ? values[i] : "NULL");
  printf("\n");
  return 0;
}

static void exec(sqlite3 *db, const char *label, const char *sql) {
  char *error = NULL;
  int rc = sqlite3_exec(db, sql, print_result, (void *)label, &error);
  if (rc != SQLITE_OK) printf("%s rc=%d error=%s\n", label, rc, error ? error : "(null)");
  sqlite3_free(error);
}

/* The statement-level surface FMDB drives: prepare/bind/step/column, types,
 * changes, rowids, errors, FTS4 (NetNewsWire's search table) and WAL. */
static void crud(const char *path) {
  sqlite3 *db = NULL;
  int rc = sqlite3_open_v2(path, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
  printf("crud open rc=%d\n", rc);
  exec(db, "crud wal", "PRAGMA journal_mode=WAL");
  exec(db, "crud create", "CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT, n INTEGER, x REAL, b BLOB, z)");
  sqlite3_stmt *st = NULL;
  rc = sqlite3_prepare_v2(db, "INSERT INTO t (name, n, x, b, z) VALUES (?, ?, ?, ?, ?)", -1, &st, NULL);
  printf("crud prepare rc=%d params=%d\n", rc, sqlite3_bind_parameter_count(st));
  const char *names[] = {"alpha", "b\xc3\xa9ta", "gamma"};
  for (int i = 0; i < 3; i++) {
    sqlite3_bind_text(st, 1, names[i], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int64(st, 2, (sqlite3_int64)1 << (20 * i));
    sqlite3_bind_double(st, 3, 1.5 * i);
    unsigned char blob[3] = {(unsigned char)i, 0xff, 0x00};
    sqlite3_bind_blob(st, 4, blob, 3, SQLITE_TRANSIENT);
    sqlite3_bind_null(st, 5);
    rc = sqlite3_step(st);
    printf("crud insert rc=%d changes=%d rowid=%lld\n", rc, sqlite3_changes(db), sqlite3_last_insert_rowid(db));
    sqlite3_reset(st);
  }
  sqlite3_finalize(st);
  rc = sqlite3_prepare_v2(db, "SELECT id, name, n, x, b, z, length(name) FROM t WHERE n >= :min ORDER BY id", -1, &st, NULL);
  printf("crud select rc=%d index=%d columns=%d\n", rc, sqlite3_bind_parameter_index(st, ":min"), sqlite3_column_count(st));
  sqlite3_bind_int(st, 1, 2);
  while ((rc = sqlite3_step(st)) == SQLITE_ROW) {
    printf("crud row");
    for (int c = 0; c < sqlite3_column_count(st); c++) {
      printf(" %s:%d", sqlite3_column_name(st, c), sqlite3_column_type(st, c));
      if (sqlite3_column_type(st, c) == SQLITE_BLOB) {
        const unsigned char *b = sqlite3_column_blob(st, c);
        printf("=");
        for (int k = 0; k < sqlite3_column_bytes(st, c); k++) printf("%02x", b[k]);
      } else if (sqlite3_column_type(st, c) != SQLITE_NULL) {
        printf("=%s", (const char *)sqlite3_column_text(st, c));
      }
    }
    printf(" data_count=%d\n", sqlite3_data_count(st));
  }
  printf("crud done rc=%d\n", rc);
  sqlite3_finalize(st);
  exec(db, "crud fts create", "CREATE VIRTUAL TABLE search USING fts4(title, body)");
  exec(db, "crud fts insert", "INSERT INTO search (title, body) VALUES ('Linux guests', 'Mach-O binaries run under machorun'), ('SQLite', 'an amalgamation built as a dylib')");
  exec(db, "crud fts match", "SELECT rowid, title FROM search WHERE search MATCH 'machorun OR dylib' ORDER BY rowid");
  exec(db, "crud fts snippet", "SELECT snippet(search) AS s FROM search WHERE search MATCH 'amalgamation'");
  exec(db, "crud json", "SELECT json_object('a', 1, 'b', json_array(2, 3)) AS j");
  exec(db, "crud math", "SELECT round(sqrt(2), 6) AS r");
  exec(db, "crud error", "SELECT * FROM missing_table");
  rc = sqlite3_prepare_v2(db, "SELEKT 1", -1, &st, NULL);
  printf("crud syntax rc=%d errcode=%d errmsg=%s\n", rc, sqlite3_errcode(db), sqlite3_errmsg(db));
  exec(db, "crud count", "SELECT count(*) AS c FROM t");
  printf("crud close rc=%d\n", sqlite3_close(db));
}

int main(void) {
  printf("libversion %s threadsafe %d\n", sqlite3_libversion(), sqlite3_threadsafe());
  printf("sourceid %s\n", sqlite3_sourceid());
  for (int i = 0; ; i++) {
    const char *o = sqlite3_compileoption_get(i);
    if (!o) break;
    printf("opt %s\n", o);
  }
  pragmas("memory", ":memory:");
  const char *tmp = getenv("TMPDIR");
  char path[1024];
  snprintf(path, sizeof path, "%s/guestsqliteoptions-%d.db", tmp && *tmp ? tmp : "/tmp", (int)getpid());
  unlink(path);
  pragmas("file", path);
  unlink(path);
  crud(":memory:");
  crud(path);
  unlink(path);
  char side[1100];
  snprintf(side, sizeof side, "%s-wal", path);
  unlink(side);
  snprintf(side, sizeof side, "%s-shm", path);
  unlink(side);
  return 0;
}
