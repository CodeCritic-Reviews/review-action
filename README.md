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

## AI Disclosure

CodeCritic uses artificial intelligence models to analyze your code. Review results are **AI-generated** and:

- May contain inaccuracies, false positives, or false negatives
- Are not a substitute for human code review
- Should always be verified before applying to your codebase
- Do not constitute professional security audits or compliance assessments

The AI model used may vary and is configured by the CodeCritic service.

## Data & Privacy

When you use this action, the following data is sent to the CodeCritic API (`api.code-critic.com`):

- Repository name and metadata
- Pull request title, description, and branch information
- Code diffs (fetched via GitHub API)
- Your CodeCritic API key

**What stays local:**
- Your `GITHUB_TOKEN` is never sent to CodeCritic — it is only used to post PR comments

**What happens on the server:**
- Code is sent to an AI model provider (via OpenRouter) for analysis
- Code is processed in real-time and not permanently stored
- Review results (scores, summaries) are stored in your CodeCritic account

Full details: [Privacy Policy](https://code-critic.com/privacy) | [Terms of Service](https://code-critic.com/terms)

## Limitations

This action **cannot**:

- Execute or run your code
- Access runtime behavior or logs
- Detect all possible bugs or security vulnerabilities
- Replace thorough manual code review for critical systems
- Analyze binary files, images, or non-text content

Review quality depends on the AI model, code complexity, and the amount of context available in the diff.

## Support & Feedback

- **Bug reports & feature requests:** [GitHub Issues](https://github.com/CodeCritic-Reviews/review-action/issues)
- **Email:** support@code-critic.com
- **Security vulnerabilities:** See [SECURITY.md](SECURITY.md)
- **Documentation:** [code-critic.com](https://code-critic.com)

## License

MIT — see [LICENSE](LICENSE)
