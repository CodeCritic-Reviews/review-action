# CodeCritic Review Action

AI-powered code review for your pull requests.

## Quick Start

```yaml
name: CodeCritic Review
on:
  pull_request:
    types: [opened, synchronize]
  workflow_dispatch:

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: CodeCritic-Reviews/review-action@v1
        with:
          api_key: ${{ secrets.CODECRITIC_API_KEY }}
```

## Setup

1. Get your API key from [CodeCritic Dashboard](https://code-critic.com/dashboard)
2. Add `CODECRITIC_API_KEY` to your repository secrets (Settings → Secrets → Actions)
3. Create `.github/workflows/codecritic.yml` with the workflow above
4. Open a pull request — the review runs automatically

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `api_key` | **Yes** | — | Your CodeCritic API key |
| `api_url` | No | `https://api.code-critic.com` | API endpoint URL |
| `wait_for_completion` | No | `true` | Wait for review to finish |
| `post_comment` | No | `true` | Post results as a PR comment |
| `timeout` | No | `600` | Max wait time in seconds |

## Outputs

| Output | Description |
|---|---|
| `review_id` | ID of the created review |
| `score` | Code quality score (0–100) |
| `status` | Final status: `completed`, `failed`, or `timeout` |

## Examples

### Basic — run on every PR

```yaml
- uses: CodeCritic-Reviews/review-action@v1
  with:
    api_key: ${{ secrets.CODECRITIC_API_KEY }}
```

### Fire-and-forget (don't wait for results)

```yaml
- uses: CodeCritic-Reviews/review-action@v1
  with:
    api_key: ${{ secrets.CODECRITIC_API_KEY }}
    wait_for_completion: 'false'
```

### Use score in subsequent steps

```yaml
- uses: CodeCritic-Reviews/review-action@v1
  id: codecritic
  with:
    api_key: ${{ secrets.CODECRITIC_API_KEY }}

- name: Fail if score too low
  if: steps.codecritic.outputs.score < 50
  run: |
    echo "Code quality score ${{ steps.codecritic.outputs.score }} is below threshold"
    exit 1
```

## License

MIT
