# theAIgincy — Micro-App Factory

Monorepo for theAIgincy's portfolio of small, standalone iOS apps. Every
app is independently buildable, has its own Xcode project, bundle
identifier, and documentation, and shares only genuinely generic factory
infrastructure. Governing standards live in
[`ShouldITextHim/MICRO_APP_FACTORY.md`](ShouldITextHim/MICRO_APP_FACTORY.md)
(see `apps/start-me/docs/DECISIONS.md` for why that file hasn't moved to
the repo root yet).

## Apps

### Should I Text Him?
Status: In development
Path: [`ShouldITextHim/`](ShouldITextHim/)
A tiny, sharp-tongued app that judges a text you're about to send and
offers a rewrite.

### Start Me
Status: V1 built, pending Xcode build verification and founder actions
(see [`apps/start-me/docs/RELEASE_CHECKLIST.md`](apps/start-me/docs/RELEASE_CHECKLIST.md))
Path: [`apps/start-me/`](apps/start-me/)
Type the thing you're stuck on, get one tiny physical first step, run a
60-second timer. Fully local, no account, no AI, no backend.

### Pick For Me
Status: Planned

## Repository layout

```
theaigency/
├── README.md
├── .gitignore                  repo-wide Xcode/SPM ignores
├── ShouldITextHim/              App #1 (still at repo root — see note above)
└── apps/
    └── start-me/                App #2
```

New apps should be added under `apps/<slug>/` with their own
`.xcodeproj`, app target, test target, and `docs/` directory, following
the structure in `apps/start-me/` as the current reference example.
