## Lube Logger Companion App – Static Site

This branch hosts a **pure HTML/CSS/JS** marketing site for the Lube Logger Companion App. It uses Bootstrap 5 from a CDN and lives entirely inside the `docs/` folder so it can be published with GitHub Pages (Project Settings → Pages → Branch `gh-pages-site`, folder `/docs`).

### Structure

```
docs/
├── index.html          # Landing page (pure HTML + Bootstrap 5)
└── assets/
    └── css/
        └── styles.css  # Custom accents layered on top of Bootstrap
```

### Local Preview

Because it’s completely static, you can open `docs/index.html` directly in a browser or serve it with any simple HTTP server, for example:

```bash
python -m http.server --directory docs 8080
```

Then visit `http://localhost:8080`.

### Customization Checklist

- Swap placeholder screenshots in the “Preview the experience” section (`docs/assets/images/...`).
- Update contact links (footer + CTA) as needed.
- Adjust copy, roadmap items, and feature descriptions to match the latest release.

### Deploying to GitHub Pages

1. Commit and push the `gh-pages-site` branch.
2. In your GitHub repository, go to **Settings → Pages**.
3. Select the branch (`gh-pages-site`) and folder (`/docs`).
4. Save. GitHub Pages will build and publish automatically.

Enjoy showcasing the app! 🎉

