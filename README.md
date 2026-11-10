# trendseeq-web

Static website for TrendSeeq, LLC at https://www.trendseeq.com, hosted free on GitHub Pages.

No build step: plain HTML and one stylesheet (`assets/css/site.css`).

| Page | Path | Notes |
|---|---|---|
| Home | `index.html` | Consulting services and product highlights |
| Products | `products/index.html` | One `<article id="...">` per app; link with `/products/#id` |
| Support | `support/index.html` | App Store "Support URL": https://www.trendseeq.com/support |
| Privacy | `privacy/index.html` | App Store "Privacy Policy URL": https://www.trendseeq.com/privacy. Update the effective date when you change it. |

## Commands

```sh
./deploy.sh preview   # local preview at http://localhost:8000
./deploy.sh           # commit + push; GitHub Pages redeploys in ~1 minute
./deploy.sh status    # Pages, certificate and DNS status
./deploy.sh https     # enforce HTTPS (once, after DNS and the certificate are ready)
```

## Adding a product

1. Put a 256px+ icon in `assets/img/`.
2. Copy an `<article class="card product">` block in `products/index.html`.
3. Add a tile to the Products grid in `index.html`, a FAQ section in `support/index.html`,
   and a section in `privacy/index.html` describing what data the app uses.
4. `./deploy.sh`
