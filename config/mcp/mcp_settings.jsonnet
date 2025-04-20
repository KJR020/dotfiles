/**
 * MCPサーバー設定ファイル
 * シークレット情報はsecrets.jsonnetから取得
 */

// シークレット設定をインポート
local secrets = import 'secrets.jsonnet';

{
  mcpServers: {
    // ファイルシステム・データストレージ関連
    filesystem: {
      command: "npx",
      args: ["-y", "@modelcontextprotocol/server-filesystem", secrets.homePath],
    },
    memory: {
      command: "npx",
      args: ["-y", "@modelcontextprotocol/server-memory"],
    },

    // ネットワーク・通信関連
    fetch: {
      command: "uvx",
      args: ["mcp-server-fetch"],
    },
    // バージョン管理関連
    git: {
      command: "uvx",
      args: [
        "mcp-server-git",
        "--repository",
        secrets.gitRepository,
      ],
    },
    github: {
      command: "docker",
      args: [
        "run",
        "-i",
        "--rm",
        "-e",
        "GITHUB_PERSONAL_ACCESS_TOKEN",
        "ghcr.io/github/github-mcp-server"
      ],
      env: {
        GITHUB_PERSONAL_ACCESS_TOKEN: secrets.githubPat,
      }
    },

    // ブラウザ・ウェブ操作関連
    puppeteer: {
      command: "npx",
      args: ["-y", "@modelcontextprotocol/server-puppeteer"],
    },
    playwright: {
      command: "npx",
      args: ["-y", "@playwright/mcp@latest"],
    },

    // デザイン・クリエイティブツール関連
    "figma-developer-mcp": {
      command: "npx",
      args: ["-y", "figma-developer-mcp", "--stdio"],
      env: {
        FIGMA_API_KEY: secrets.figmaApiKey,
      },
    },

    // メディア関連
    youtube: {
      command: "npx",
      args: ["-y", "@anaisbetts/mcp-youtube"],
    },

    // コミュニケーション・チャット関連
    slack: {
      command: "npx",
      args: ["-y", "@modelcontextprotocol/server-slack"],
      env: {
        SLACK_BOT_TOKEN: secrets.slackBotToken,
        SLACK_TEAM_ID: secrets.slackTeamId,
      },
    },

    // AI・思考プロセス関連
    "sequential-thinking": {
      command: "npx",
      args: ["-y", "@modelcontextprotocol/server-sequential-thinking"],
    },

    // ドキュメント・リファレンス関連
    "awslabs.aws-documentation-mcp-server": {
      command: "uvx",
      args: ["awslabs.aws-documentation-mcp-server@latest"],
      env: {
        FASTMCP_LOG_LEVEL: secrets.fastmcpLogLevel,
      },
      disabled: false,
      autoApprove: [],
    },
  },
}
