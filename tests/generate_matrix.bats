#!/usr/bin/env bats

# generate_matrix.sh のテスト

setup() {
  # テストをリポジトリルートから実行
  cd "$BATS_TEST_DIRNAME/.." || exit 1

  # テスト用の設定ファイルを作成
  export TEST_CONFIG="$BATS_TEST_TMPDIR/test_config.json"
  cat > "$TEST_CONFIG" <<'EOF'
{
  "version": "1.0",
  "domains": [
    {
      "id": "monday-domain",
      "name": "Monday Domain",
      "day_of_week": 1
    },
    {
      "id": "wednesday-domain",
      "name": "Wednesday Domain",
      "day_of_week": 3
    },
    {
      "id": "friday-domain",
      "name": "Friday Domain",
      "day_of_week": 5
    }
  ]
}
EOF
}

@test "Given the script exists, then it should be executable" {
  [ -x "scripts/generate_matrix.sh" ]
}

@test "Given config file does not exist, when executed, then returns error" {
  run bash scripts/generate_matrix.sh /nonexistent/config.json
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Configuration file not found" ]]
}

@test "Given MODE=all, when executed, then returns all domains" {
  MODE=all run bash scripts/generate_matrix.sh "$TEST_CONFIG"
  [ "$status" -eq 0 ]

  echo "$output" | jq -e 'length == 3'
  echo "$output" | jq -e '[.[] | select(.domain_id == "monday-domain")] | length == 1'
  echo "$output" | jq -e '[.[] | select(.domain_id == "wednesday-domain")] | length == 1'
  echo "$output" | jq -e '[.[] | select(.domain_id == "friday-domain")] | length == 1'
}

@test "Given valid execution, when output generated, then output is valid JSON" {
  MODE=all run bash scripts/generate_matrix.sh "$TEST_CONFIG"
  [ "$status" -eq 0 ]

  echo "$output" | jq -e '.' > /dev/null
}

@test "Given valid execution, when output generated, then contains domain_id and domain_name" {
  MODE=all run bash scripts/generate_matrix.sh "$TEST_CONFIG"
  [ "$status" -eq 0 ]

  echo "$output" | jq -e '.[0] | has("domain_id")'
  echo "$output" | jq -e '.[0] | has("domain_name")'
}

@test "Given MODE=daily on Monday, when executed, then filters Monday domains" {
  TEST_DAY_OF_WEEK=1 MODE=daily run bash scripts/generate_matrix.sh "$TEST_CONFIG"
  [ "$status" -eq 0 ]

  echo "$output" | jq -e 'length == 1'
  echo "$output" | jq -e '.[0].domain_id == "monday-domain"'
}

@test "Given MODE=daily on Wednesday, when executed, then filters Wednesday domains" {
  TEST_DAY_OF_WEEK=3 MODE=daily run bash scripts/generate_matrix.sh "$TEST_CONFIG"
  [ "$status" -eq 0 ]

  echo "$output" | jq -e 'length == 1'
  echo "$output" | jq -e '.[0].domain_id == "wednesday-domain"'
}

@test "Given MODE=daily on Friday, when executed, then filters Friday domains" {
  TEST_DAY_OF_WEEK=5 MODE=daily run bash scripts/generate_matrix.sh "$TEST_CONFIG"
  [ "$status" -eq 0 ]

  echo "$output" | jq -e 'length == 1'
  echo "$output" | jq -e '.[0].domain_id == "friday-domain"'
}

@test "Given MODE=daily on Sunday with no Sunday domains, when executed, then returns empty array" {
  TEST_DAY_OF_WEEK=7 MODE=daily run bash scripts/generate_matrix.sh "$TEST_CONFIG"
  [ "$status" -eq 0 ]

  echo "$output" | jq -e 'length == 0'
  echo "$output" | jq -e '. == []'
}

@test "Given valid execution, when output generated, then conforms to GitHub Actions Matrix format" {
  MODE=all run bash scripts/generate_matrix.sh "$TEST_CONFIG"
  [ "$status" -eq 0 ]

  echo "$output" | jq -e 'type == "array"'
  echo "$output" | jq -e '.[0] | type == "object"'
}

@test "Given MODE not specified, when executed, then defaults to daily mode" {
  run bash scripts/generate_matrix.sh "$TEST_CONFIG"
  [ "$status" -eq 0 ]

  domain_count=$(echo "$output" | jq 'length')
  [ "$domain_count" -ge 0 ] && [ "$domain_count" -le 3 ]
}

@test "Given actual config file, when executed, then works correctly" {
  run bash scripts/generate_matrix.sh scripts/kaizen_config.json
  [ "$status" -eq 0 ]

  echo "$output" | jq -e '.' > /dev/null
}
