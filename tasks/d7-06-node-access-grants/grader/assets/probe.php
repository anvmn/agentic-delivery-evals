<?php

/**
 * @file
 * Seed users/records, rebuild grants, and probe visibility via node_access-
 * tagged listing queries as each user (drush php-script). Prints JSON.
 */

// Authenticated users must be able to reach content at all.
user_role_grant_permissions(DRUPAL_AUTHENTICATED_RID, array('access content'));

function _ra_mkuser($name, $center) {
  if ($u = user_load_by_name($name)) {
    user_delete($u->uid);
  }
  $account = new stdClass();
  $account->name = $name;
  $account->mail = $name . '@example.test';
  $account->status = 1;
  $account->is_new = TRUE;
  $account->field_user_center[LANGUAGE_NONE][0]['value'] = $center;
  $account = user_save($account);
  return user_load($account->uid, TRUE);
}

function _ra_mkrecord($title, $center) {
  $node = new stdClass();
  $node->type = 'record';
  node_object_prepare($node);
  $node->title = $title;
  $node->language = LANGUAGE_NONE;
  $node->status = 1;
  $node->uid = 1;
  $node->field_center_id[LANGUAGE_NONE][0]['value'] = $center;
  node_save($node);
  return (int) $node->nid;
}

function _ra_visible($account) {
  $q = db_select('node', 'n')->fields('n', array('nid'))->condition('n.type', 'record');
  $q->addTag('node_access');
  $q->addMetaData('account', $account);
  $nids = array_map('intval', $q->execute()->fetchCol());
  sort($nids);
  return $nids;
}

$alice = _ra_mkuser('ra_alice', 7);
$bob = _ra_mkuser('ra_bob', 9);
$c7 = array(_ra_mkrecord('rec-7a', 7), _ra_mkrecord('rec-7b', 7));
$c9 = array(_ra_mkrecord('rec-9a', 9));
sort($c7);
sort($c9);

node_access_rebuild();
drupal_static_reset('node_access_view_all_nodes');

print drupal_json_encode(array(
  'alice' => _ra_visible($alice),
  'bob' => _ra_visible($bob),
  'c7' => $c7,
  'c9' => $c9,
));
