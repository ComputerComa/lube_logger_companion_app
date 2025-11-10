# Lube Logger Companion App — GitHub Pages Site

This branch scaffolds a Jekyll-powered marketing/documentation site for the Lube Logger Companion App. The site lives under the `docs/` directory so it can be published with GitHub Pages (Project → Settings → Pages → Branch `gh-pages-site`, folder `/docs`).

## Local development

1. Ensure you have Ruby and Bundler installed (Ruby 3.x recommended).
2. From the repo root:

   ```bash
   bundle init    # only needed the first time
   bundle add jekyll webrick
   bundle exec jekyll serve --source docs --livereload
   ```

3. Open <http://localhost:4000> to preview changes. The livereload flag hot-reloads edits to layouts, content, and CSS.

> **Note:** If you already have a global Jekyll install you can simply run `jekyll serve --source docs`.

## Customization checklist

- Update `docs/_config.yml` with your GitHub handle, repository name, and contact links.
- Replace placeholder screenshots referenced in `docs/index.md` with real images under `docs/assets/images/`.
- Adjust copy, roadmap milestones, and feature highlights to match your latest release.
- Configure GitHub Pages (Settings → Pages) to serve from this branch and the `/docs` folder.

## Deploying

1. Commit updates on the `gh-pages-site` branch.
2. Push to GitHub: `git push origin gh-pages-site`.
3. GitHub Pages will build and publish automatically. The site will be available at `https://<username>.github.io/<repo>/`.

Happy documenting!

