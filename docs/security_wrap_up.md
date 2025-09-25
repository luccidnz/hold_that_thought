**Security**

- Repo history was rewritten to scrub secrets. If local clone diverges:

```
git fetch --all
git reset --hard origin/feature/phase10-auth-rag-android-e2ee
git clean -fdx
```

- Rotate Supabase anon and service keys in the Dashboard and update local .env or repo secrets (never committed). 
- See docs/SECURITY_ROTATION.md for complete guide.
