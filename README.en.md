# dsh-project-desktop-development

English · [简体中文](README.md)

Development workspace for `dsh-project-desktop`. It holds project metadata, task records and working agreements that the DSH Project capability loads. **Product source code does not live here.**

## Layout

```text
.
├── AGENT.md                                      # Project-level agent instruction entry
├── dsh-project-desktop-development.agent-project # Project manifest: resources and memory declarations
├── memory/working-agreements.md                  # Working agreements and verification flow (loaded into context)
├── tasks/<task name>/task.md                     # v3 task records, attachments under artifacts/
├── skills/index.yaml                             # Project-level skills (currently empty)
├── mcp/servers.yaml                              # Project-level MCP servers (currently empty)
└── resources/                                    # Checkouts of the related repositories, not version controlled
```

## Related repositories

Product source is maintained in two separate repositories. `resources/` here only holds their checkouts and is excluded by `.gitignore`, so it is never distributed with this repository:

- [dsh-project-desktop](https://github.com/admintertar/dsh-project-desktop) — Electron shell and application layer: project launch experience, per-project window isolation, recovery and safe mode, update adapter.
- [dsh-plugin-project](https://github.com/admintertar/dsh-plugin-project) — the project / resource / task / skill / MCP / memory plugin.

Both are built on public upstreams, referenced read-only at pinned commits:

- [deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness) (MIT)
- [anywhere-labs/dsh-desktop](https://github.com/anywhere-labs/dsh-desktop) (MIT)

This is an independent project, not an official release from DeepSeek or Anywhere Labs.

## Task records

`tasks/<task name>/task.md` records work independently of any conversation: objective, acceptance criteria, evidence chain and verification results. Attachments such as screenshots live in the sibling `artifacts/` directory. Local machine paths in those records have been redacted.

## License

All rights in this repository's original content are reserved; see [LICENSE](LICENSE). Public readability does not grant a license to use, modify or redistribute.
