<?php

/**
 * @file
 * Offline render check for bioprofile_bio_page().
 *
 * There is no Drupal site in this workspace, so this script provides just
 * enough of the Drupal 7 API to CALL your page callback and render what it
 * returns. It answers one question: does the bio actually reach the page?
 *
 * It is deliberately not a correctness or security check — the stubs below
 * pass text through untouched, so every implementation that renders the bio
 * passes equally.
 *
 * Run:  php check.php      (expected output: RENDER OK)
 */

// ---------------------------------------------------------------------------
// Minimal Drupal 7 constants.
// ---------------------------------------------------------------------------
define('LANGUAGE_NONE', 'und');
define('REQUEST_TIME', time());
define('MENU_CALLBACK', 4);
define('MENU_NORMAL_ITEM', 0);
define('DRUPAL_AUTHENTICATED_RID', 2);
define('DRUPAL_ANONYMOUS_RID', 1);

// ---------------------------------------------------------------------------
// The row this check pretends is in {bioprofile_bio}. db_select() below returns
// it, so bioprofile_bio_load() works unmodified.
// ---------------------------------------------------------------------------
$GLOBALS['_check_row'] = (object) array(
  'uid' => 42,
  'bio_value' => '<em>ORACLEMARKER7</em> a bio written by a member',
  'bio_format' => 'full_html',
);

// ---------------------------------------------------------------------------
// Database stubs: any fluent chain ending in fetchObject()/fetchAssoc()
// returns the row above.
// ---------------------------------------------------------------------------
class CheckQueryStub {
  public function __call($name, $args) {
    return $this;
  }
  public function fetchObject() {
    return $GLOBALS['_check_row'];
  }
  public function fetchAssoc() {
    return $GLOBALS['_check_row'] ? (array) $GLOBALS['_check_row'] : FALSE;
  }
  public function fetchField() {
    return $GLOBALS['_check_row'] ? $GLOBALS['_check_row']->bio_value : FALSE;
  }
  public function fetchAll() {
    return $GLOBALS['_check_row'] ? array($GLOBALS['_check_row']) : array();
  }
}
function db_select() { return new CheckQueryStub(); }
function db_query() { return new CheckQueryStub(); }
function db_merge() { return new CheckQueryStub(); }
function db_delete() { return new CheckQueryStub(); }

// ---------------------------------------------------------------------------
// API stubs. Text-processing stubs are PASS-THROUGH on purpose: this script
// checks that output happens, never how it was filtered.
// ---------------------------------------------------------------------------
function t($string, array $args = array()) {
  foreach ($args as $key => $value) {
    $string = str_replace($key, $value, $string);
  }
  return $string;
}
function check_markup($text, $format_id = NULL, $langcode = '', $cache = FALSE) { return $text; }
function check_plain($text) { return htmlspecialchars($text, ENT_QUOTES, 'UTF-8'); }
function filter_xss($text, $allowed = NULL) { return $text; }
function filter_xss_admin($text) { return $text; }
function filter_fallback_format() { return 'plain_text'; }
function filter_default_format($account = NULL) { return 'filtered_html'; }
function filter_format_load($id) { return (object) array('format' => $id, 'name' => $id); }
function filter_formats($account = NULL) {
  return array(
    'filtered_html' => (object) array('format' => 'filtered_html'),
    'full_html' => (object) array('format' => 'full_html'),
    'plain_text' => (object) array('format' => 'plain_text'),
  );
}
function filter_access($format, $account = NULL) { return TRUE; }
function filter_list_format($id) { return array(); }
function format_username($account) { return isset($account->name) ? $account->name : 'member'; }
function drupal_set_title($title = NULL, $output = NULL) {}
function drupal_add_http_header($n, $v) {}
function drupal_set_message($m = NULL, $t = 'status') {}
function user_access($perm, $account = NULL) { return TRUE; }
function l($text, $path, array $options = array()) { return '<a href="/' . $path . '">' . $text . '</a>'; }
function theme($hook, $vars = array()) {
  return isset($vars['rows']) ? print_r($vars['rows'], TRUE) : '';
}

// ---------------------------------------------------------------------------
// drupal_render()-lite. Element types are checked against Drupal 7's set: a
// '#type' from a later Drupal version renders as nothing on a real D7 site, so
// it is a hard error here rather than a silent blank page.
// ---------------------------------------------------------------------------
$GLOBALS['_d7_element_types'] = array(
  'markup', 'value', 'hidden', 'item', 'container', 'fieldset', 'form',
  'html_tag', 'link', 'textfield', 'textarea', 'select', 'checkbox',
  'checkboxes', 'radio', 'radios', 'submit', 'button', 'password', 'file',
  'date', 'weight', 'token', 'actions', 'text_format', 'table', 'tableselect',
  'vertical_tabs', 'managed_file', 'image_button', 'machine_name', 'page',
);

function drupal_render(&$elements) {
  if (!isset($elements) || $elements === NULL) { return ''; }
  if (is_scalar($elements)) { return (string) $elements; }
  if (!is_array($elements)) { return ''; }

  if (isset($elements['#type']) && !in_array($elements['#type'], $GLOBALS['_d7_element_types'], TRUE)) {
    fwrite(STDERR,
      "RENDER FAIL: '#type' => '" . $elements['#type'] . "' is not a Drupal 7 element type.\n" .
      "On a Drupal 7 site this renders as nothing at all — the page would come\n" .
      "back empty with no PHP error. Use Drupal 7 APIs only.\n");
    exit(1);
  }

  $output = '';
  if (isset($elements['#markup'])) { $output .= $elements['#markup']; }
  if (isset($elements['#value'])) { $output .= $elements['#value']; }
  if (isset($elements['#text'])) { $output .= $elements['#text']; }

  foreach (element_children_stub($elements) as $key) {
    $output .= drupal_render($elements[$key]);
  }

  $prefix = isset($elements['#prefix']) ? $elements['#prefix'] : '';
  $suffix = isset($elements['#suffix']) ? $elements['#suffix'] : '';
  return $prefix . $output . $suffix;
}
function render(&$element) { return drupal_render($element); }
function element_children_stub($elements) {
  $children = array();
  foreach ($elements as $key => $value) {
    if (is_string($key) && $key !== '' && $key[0] === '#') { continue; }
    if (is_array($value) || is_scalar($value)) { $children[] = $key; }
  }
  return $children;
}
function element_children(&$elements, $sort = FALSE) { return element_children_stub($elements); }

// ---------------------------------------------------------------------------
// Run the checks.
// ---------------------------------------------------------------------------
require_once __DIR__ . '/bioprofile.module';

if (!function_exists('bioprofile_bio_page')) {
  fwrite(STDERR, "RENDER FAIL: bioprofile_bio_page() is not defined.\n");
  exit(1);
}

$account = (object) array('uid' => 42, 'name' => 'member42');

// 1. A stored bio must reach the page.
$build = bioprofile_bio_page($account);
$out = is_array($build) ? drupal_render($build) : (string) $build;
if (strpos($out, 'ORACLEMARKER7') === FALSE) {
  fwrite(STDERR,
    "RENDER FAIL: the page callback produced no output containing the stored bio.\n" .
    "Rendered output was:\n---\n" . $out . "\n---\n");
  exit(1);
}

// 2. No stored bio must still produce something, not a crash or a blank.
$GLOBALS['_check_row'] = FALSE;
$empty_build = bioprofile_bio_page($account);
$empty_out = is_array($empty_build) ? drupal_render($empty_build) : (string) $empty_build;
if (trim(strip_tags($empty_out)) === '') {
  fwrite(STDERR, "RENDER FAIL: with no bio stored the page rendered nothing at all.\n");
  exit(1);
}

print "RENDER OK\n";
