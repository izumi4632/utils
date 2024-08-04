<?php

// つかいかた: php ./this_file.php '{ "advisories": { "hoge": [ { "advisoryId": "hoge", "packageName": "hoge", "affectedVersions": "<1 || >=1 <1", "title": "nya-n", "cve": null, "link": "https://example.com", "reportedAt": "?", "sources": [ ? }'

define('SLACK_WEBHOOK_URL', 'ひみつ');

$INPUT_COMPOSER_AUDIT = $argv[1];
$INPUT_YARN_AUDIT     = $argv[2];

class Parser {
  // input: INPUT_COMPOSER_AUDIT
  // output: [{title=>$title, cve_url=>$cve_url}, {}, ..., {}]
  public static function parse_input_from_composer_audit_json($input) {
    $data       = json_decode($input, true)["advisories"];
    $parsedData = [];
    foreach ($data as $advisory) {
      foreach ($advisory as $finding) {
        $title        = $finding['title'] ?? 'No title available';
        $cve_url      = $finding['link'] ?? 'No link available';
        $parsedData[] = ['title' => $title, 'cve_url' => $cve_url];
      }
    }
    return $parsedData;
  }

  // input: INPUT_COMPOSER_AUDIT
  // output: [{title=>$title, cve_url=>$cve_url}, {}, ..., {}]
  public static function parse_input_from_yarn_audit_json_lines($input) {
    $jsonlines = explode(PHP_EOL, $input);
    $parsedData = [];
    foreach ($jsonlines as $line) {
      if (trim($line) === '') {continue;} // Skip empty lines

      $jsonLine = json_decode($line, true);
      if ($jsonLine['type'] !== 'auditAdvisory') {continue;} // Skip if not auditAdvisory
      $cve_url = $jsonLine['data']['advisory']['url'] ?? 'No url available';
      $title   = $jsonLine['data']['advisory']['title'] ?? 'No title available';
      $parsedData[] = ['title' => $title, 'cve_url' => $cve_url];
    }
    return $parsedData;
  }
}

class PostToSlack {
  public static function post(array $data, string $url): void {
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'POST');
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

    $response = curl_exec($ch);
    curl_close($ch);

    if ($response === false) {
      error_log('Curl error: ' . curl_error($ch));
    }
  }

  public static function posts_parsed_data(array $parsed_data, string $url): void {
    foreach ($parsed_data as $item) {
      $text = "title: ".$item['title']."\ncve_url: ". $item['cve_url'];
      self::post(['text' => $text], $url);
    }
  }
}

// 実行
PostToSlack::posts_parsed_data(Parser::parse_input_from_composer_audit_json($INPUT_COMPOSER_AUDIT), SLACK_WEBHOOK_URL);
PostToSlack::posts_parsed_data(Parser::parse_input_from_yarn_audit_json_lines($INPUT_YARN_AUDIT), SLACK_WEBHOOK_URL);
