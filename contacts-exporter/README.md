# contacts-exporter

Apple Contacts → markdown vault.

## Data source

`~/Library/Application Support/AddressBook/Sources/<UUID>/AddressBook-v22.abcddb`
— one SQLite store per account (iCloud, Google, local). The exporter
iterates every source and joins related rows from:

- `ZABCDRECORD` — names, organization, title, department
- `ZABCDEMAILADDRESS` — emails (with `_$!<Home>!$_` label normalized)
- `ZABCDPHONENUMBER` — phone numbers
- `ZABCDPOSTALADDRESS` — addresses
- `ZABCDURLADDRESS` — URLs
- `ZABCDSOCIALPROFILE` — social handles

Read-only via `bin/lib/apple_sqlite_snapshot.open_immutable`. Contacts.app
can stay open — the WAL turnover is slow and a few-minute staleness is
not material for contact-list exports.

## Subcommands

```bash
./scripts/contacts-exporter status      # source + contact counts
./scripts/contacts-exporter list        # flat alphabetical list
./scripts/contacts-exporter search Q    # name + org + email substring
./scripts/contacts-exporter show NAME   # full details, all matching
./scripts/contacts-exporter export      # write vault under VAULT_PATH
```

## Vault layout

```
exported/contacts/
├── _index.md                  master alphabetical list
├── by-source/<uuid>/_index.md per-source breakdown
└── by-name/<slug>.md          one contact per file
```

Each per-contact `.md` has the display name, role/organization, emails,
phones, postal addresses, URLs, and social handles, with source UUID
in a footer.
