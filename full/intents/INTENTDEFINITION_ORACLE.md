# Xcode semantic oracle for the open intent-definition compiler

The open generator was derived from the public plist model and semantic
observations. No Apple-generated Swift is checked into this repository.

Oracle environment on 2026-08-30:

- Xcode 26.1, build 17B55; macOS SDK 26.1.
- `intentbuilderc` SHA-256:
  `5bac81fd48923d96e0a709cbf87959d781e70f7229ee9a82cffe8c1b60c75a5a`.
- Command shape: `intentbuilderc generate -language Swift -swiftVersion 5.0
  -visibility public -moduleName MODULE`.
- Focus was generated twice into new roots. Both one-file trees were
  byte-identical; `EraseIntent.swift` SHA-256 was
  `4b8206a1e37f0bb6c13cb8ef1fb2b9fd0b0fbb360c05c73b7762a1d1eebbabb4`.

Compact tree attestations below hash the sorted `SHA-256  ./filename` records,
not a tar archive. The Apple output trees are disposable local oracle data;
only these measurements and independently written implementation remain.

| Schema | Input SHA-256 | Swift files | Oracle record-tree SHA-256 |
|---|---|---:|---|
| Focus Erase | `d73b6f7eb39cdf2c80af4e84fd737e8c2196ded95c4ff886d5e74e2e8ff413de` | 1 | `5391cae2e2bb28ed7a2bba9eebe64a41126e98891651fe9782b4d5a99025ea24` |
| Firefox QuickAction enum | `755c09de4ec66f76ec307f9544aced20375d5414d02c8744f113b97520f8d0d2` | 2 | `e7735c3bcac884c81ed5bacfc80a1ac59915ae56ba1571a9e3693d8b70d56d83` |
| Telegram object array | `f8c02468b247e9b7bff477a23161a675a70db28e60decf0772cd609b41fbcd5e` | 3 | `2ecb268de04adcce04ce0f46498cc4e9c66200ca4b3827073520f7d6ecca4d07` |
| Mastodon rich response | `29bbef3465be1b180e81ec6c7b7b5fba222b2496e2741fc8ca4067faa14eb89d` | 4 | `89f24972f8e039882b9bb0f8f33205c1ea4d00f13f806d441c274ab8ea8145ee` |
| Simplenote class overrides | `2ec00063438d207fa5ad6078b18e26bb82b8a61404872f646f3e506114e4c3e4` | 9 | `1d575819141917a38d1195c650cf259b868ca8867663e0177a62afeadc28334f` |
| Pocket Casts custom + system | `e4db174da0c66f2b538891c67088e0ebaffcf00dd362b1aeaf3e8aea0d3cf5af` | 5 | `6903f83ceee44a638bc3b5fa30b616c90ef72d7f91727b91641e821b551bc836` |
| Simplenote widget overrides | `2019f8ace2f6d2185c955a9fea1b8d3dd0f678fca4f168e9332a3ac786701d58` | 3 | `d0f8c24dd8acaec8b157e95c2e93311f135b6a2ce12f673e35f085de6582e920` |
| Mastodon primitive options | `f9595e6be0a02dae99ff12cae2e6a738be215ba9368864ecd9a6594fde20458e` | 4 | `6563e0ccc6c63ad781ff1de7a2e5102b1f8dfd5747e5c425e848eba07cf3c1eb` |

The observations establish these compatibility rules:

- custom intent class = explicit class override, otherwise `NameIntent`;
- Swift ignores Objective-C class prefixes for default custom class names;
- system intents produce no derived source and remain framework-owned;
- enum values retain declared integer indices and add a typed resolution
  result;
- custom object default fields are inherited from `INObject`; only additional
  properties are emitted;
- bare numeric and Boolean properties use `NSNumber?`, while integer enums
  use the generated nonoptional Swift enum;
- dynamic String collections use `INObjectCollection<NSString>`;
- searchable dynamic options add `searchTerm: String?`;
- response codes begin with the seven standard states and custom codes begin
  at raw value 100;
- response format placeholders produce typed static response factories.

The open generator intentionally omits Apple availability/Objective-C
attributes and proprietary comments. Its pure-Swift declarations preserve
the source-facing type and method inventory needed by Linux guests.
