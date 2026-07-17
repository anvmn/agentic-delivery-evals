<?php

/**
 * @file
 * Enable rw language, seed per-language bodies, and probe the agent's
 * language-resolution function (drush php-script). Prints JSON.
 */

if (!module_exists('locale')) {
  module_enable(array('locale'));
}
include_once DRUPAL_ROOT . '/includes/locale.inc';
$langs = language_list();
if (!isset($langs['rw'])) {
  locale_add_language('rw', 'Kinyarwanda', 'Kinyarwanda', LANGUAGE_LTR, '', '', TRUE, FALSE);
}
drupal_static_reset('language_list');
drupal_static_reset('field_available_languages');
field_info_cache_clear();

// Node 1: en + rw bodies, no language-neutral value.
$n1 = new stdClass();
$n1->type = 'article';
node_object_prepare($n1);
$n1->title = 'a1';
$n1->language = 'en';
$n1->status = 1;
$n1->uid = 1;
$n1->field_body['en'][0] = array('value' => 'English body');
$n1->field_body['rw'][0] = array('value' => 'Kinyarwanda body');
node_save($n1);

// Node 2: only a language-neutral value.
$n2 = new stdClass();
$n2->type = 'article';
node_object_prepare($n2);
$n2->title = 'a2';
$n2->language = LANGUAGE_NONE;
$n2->status = 1;
$n2->uid = 1;
$n2->field_body[LANGUAGE_NONE][0] = array('value' => 'Undefined body');
node_save($n2);

// Node 3: no body value at all.
$n3 = new stdClass();
$n3->type = 'article';
node_object_prepare($n3);
$n3->title = 'a3';
$n3->language = LANGUAGE_NONE;
$n3->status = 1;
$n3->uid = 1;
node_save($n3);

$n1 = node_load($n1->nid, NULL, TRUE);
$n2 = node_load($n2->nid, NULL, TRUE);
$n3 = node_load($n3->nid, NULL, TRUE);

print drupal_json_encode(array(
  'stored_n1' => array_keys($n1->field_body),
  'rw' => langfield_body_value($n1, 'rw'),
  'en' => langfield_body_value($n1, 'en'),
  'fallback' => langfield_body_value($n2, 'rw'),
  'empty' => langfield_body_value($n3, 'rw'),
));
