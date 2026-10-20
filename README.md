# umd-cantaloupe

UMD Libraries' Cantaloupe IIIF Image Server Docker Image

## Build

```bash
docker build -t docker.lib.umd.edu/cantaloupe:latest .
```

## Bundled images

The `static:` identifiers are resolved from `/var/images` in the container:

| Identifier | Image |
| --- | --- |
| `static:favicon` | `favicon.png` |
| `static:logo` | `logo.png` |
| `static:unavailable` | `octagon-alert.png` |
