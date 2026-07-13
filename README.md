<p align="center">
  <a href="https://code-critic.com/github-action-code-review" style="text-decoration: none; display: inline-flex; align-items: center; gap: 10px;">
    <img src="https://code-critic.com/logo.svg" alt="" width="56" height="56" />
    <span style="font-family: 'Plus Jakarta Sans', Inter, system-ui, sans-serif; font-size: 1.875rem; font-weight: 700; letter-spacing: -0.025em; background: linear-gradient(135deg, #8baafe 0%, #a67dff 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text;">CodeCritic</span>
  </a>
</p>

<p align="center">
  <strong>AI code review for pull requests in GitHub Actions</strong>
</p>

<p align="center">
  <a href="https://github.com/marketplace/actions/codecritic-review"><img src="https://img.shields.io/badge/Marketplace-CodeCritic%20Review-8b5cf6?logo=github" alt="Marketplace" /></a>
  <a href="https://code-critic.com/github-action-code-review"><img src="https://img.shields.io/badge/website-code--critic.com-6366f1" alt="Website" /></a>
  <a href="https://code-critic.com/github-code-review"><img src="https://img.shields.io/badge/docs-setup%20guide-8b5cf6" alt="Docs" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-22c55e" alt="MIT" /></a>
</p>

## Quick Start

```yaml
name: CodeCritic Review
on:
  pull_request:
    types: [opened, synchronize]
  workflow_dispatch:

permissions:
  contents: read
  pull-requests: write

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: CodeCritic-Reviews/review-action@v1
        with:
          api_key: ${{ secrets.CODECRITIC_API_KEY }}
```

The action reads pull request metadata from the GitHub event and sends it to CodeCritic. A separate `actions/checkout` step is **not required** unless you add other steps that need the workspace.

## Setup

1. Create a free account on [CodeCritic](https://code-critic.com/free-code-review) if you do not have one yet
2. Copy your API key from the [CodeCritic Dashboard](https://code-critic.com/dashboard)
3. Add `CODECRITIC_API_KEY` to your repository secrets (Settings → Secrets → Actions)
4. Create `.github/workflows/codecritic.yml` with the workflow above
5. Open a pull request - the review runs automatically

## Required permissions

If your repository uses restricted `GITHUB_TOKEN` defaults, the workflow needs:

| Permission | Why |
|---|---|
| `contents: read` | Standard read access for the job |
| `pull-requests: write` | Post the review summary as a PR comment |

Add the `permissions` block from Quick Start at the workflow level (shown there).

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

### Basic - run on every PR

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

Outputs are strings. Compare numerically with `fromJSON`:

```yaml
- uses: CodeCritic-Reviews/review-action@v1
  id: codecritic
  with:
    api_key: ${{ secrets.CODECRITIC_API_KEY }}

- name: Fail if score too low
  if: ${{ steps.codecritic.outputs.score != '' && fromJSON(steps.codecritic.outputs.score) < 50 }}
  run: |
    echo "Code quality score ${{ steps.codecritic.outputs.score }} is below threshold"
    exit 1
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| PR comment not posted | Missing `pull-requests: write` | Add the `permissions` block from Quick Start |
| `401` / API error | Invalid or missing API key | Check `CODECRITIC_API_KEY` secret and dashboard key |
| Job succeeds but no comment | `workflow_dispatch` or empty summary | Comments are PR-only; manual runs use the job summary |
| Timeout warning | Large PR or slow queue | Increase `timeout` or set `wait_for_completion: 'false'` |

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
- Your `GITHUB_TOKEN` is never sent to CodeCritic - it is only used to post PR comments

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

- **Setup guide:** [GitHub Action code review](https://code-critic.com/github-action-code-review)
- **Product docs:** [GitHub code review](https://code-critic.com/github-code-review)
- **Bug reports & feature requests:** [GitHub Issues](https://github.com/CodeCritic-Reviews/review-action/issues)
- **Email:** support@code-critic.com
- **Security vulnerabilities:** See [SECURITY.md](SECURITY.md)

## License

MIT - see [LICENSE](LICENSE)
