<?php

/**
 * @file
 * Wave 1 of the hidden holdout: mixed clinics, one unpublished, one alien type.
 */

function _cs_seed_measurement($clinic_id, $value, $status = 1, $title = NULL) {
  $node = new stdClass();
  $node->type = 'measurement';
  $node->title = $title ? $title : ('m-' . $clinic_id . '-' . $value);
  $node->language = LANGUAGE_NONE;
  $node->status = $status;
  $node->field_clinic_id[LANGUAGE_NONE][0]['value'] = $clinic_id;
  $node->field_value[LANGUAGE_NONE][0]['value'] = $value;
  node_save($node);
  return $node;
}

_cs_seed_measurement(7, 10.5, 1, 'cs-m1');
_cs_seed_measurement(7, 20.0);
_cs_seed_measurement(9, 5.25);
// Unpublished: schedules its clinic but must be excluded from totals.
_cs_seed_measurement(7, 99.0, 0);

// A non-measurement node: must be ignored without errors.
$page = new stdClass();
$page->type = 'page';
$page->title = 'cs-page-probe';
$page->language = LANGUAGE_NONE;
node_save($page);

print 'seed1-ok';
