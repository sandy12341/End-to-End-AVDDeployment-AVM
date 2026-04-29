#!/usr/bin/env bash
set -u

python3 <<'PY'
import json
import os
import subprocess


def split_scope_list(name):
    raw_value = os.environ.get(name, '')
    return [item.strip().lower() for item in raw_value.split('|') if item.strip()]


def truncate(value, length=500):
    return value[:length] if len(value) > length else value


app_group_ids = split_scope_list('RELATED_APP_GROUP_IDS')
desktop_app_group_ids = set(split_scope_list('RELATED_DESKTOP_APP_GROUP_IDS'))
remote_app_group_ids = set(split_scope_list('RELATED_REMOTE_APP_GROUP_IDS'))
preferred_app_group_type = os.environ.get('PREFERRED_APP_GROUP_TYPE', '').strip().lower()

assignments = []
errors = []

for scope in app_group_ids:
    url = f'https://management.azure.com{scope}/providers/Microsoft.Authorization/roleAssignments?api-version=2022-04-01'
    completed = subprocess.run(
        ['az', 'rest', '--method', 'get', '--url', url],
        capture_output=True,
        text=True,
        check=False,
    )

    if completed.returncode != 0:
        message = (completed.stderr or completed.stdout or '').strip()
        lowered = message.lower()
        state = 'NotAuthorized' if 'authorizationfailed' in lowered or 'forbidden' in lowered or 'does not have authorization' in lowered else 'DiscoveryFailed'
        errors.append({
            'scope': scope,
            'state': state,
            'message': truncate(message),
        })
        continue

    try:
        payload = json.loads(completed.stdout or '{}')
    except json.JSONDecodeError as exc:
        errors.append({
            'scope': scope,
            'state': 'DiscoveryFailed',
            'message': truncate(f'Unable to parse role assignment response: {exc}'),
        })
        continue

    for item in payload.get('value', []):
        properties = item.get('properties', {})
        assignment_scope = str(properties.get('scope', '')).lower()
        if assignment_scope not in app_group_ids:
            continue

        assignments.append({
            'scope': assignment_scope,
            'principalType': str(properties.get('principalType', 'Unknown')),
            'roleDefinitionId': str(properties.get('roleDefinitionId', '')).lower(),
        })

assignment_count = len(assignments)
not_authorized = any(error['state'] == 'NotAuthorized' for error in errors)
discovery_failed = any(error['state'] == 'DiscoveryFailed' for error in errors)

if not app_group_ids:
    state = 'NotEvaluated'
elif assignment_count > 0:
    state = 'Detected'
elif not_authorized:
    state = 'NotAuthorized'
elif discovery_failed:
    state = 'DiscoveryFailed'
else:
    state = 'NoneConfirmed'

if desktop_app_group_ids:
    desktop_assignment_count = len([assignment for assignment in assignments if assignment['scope'] in desktop_app_group_ids])
else:
    desktop_assignment_count = assignment_count if preferred_app_group_type == 'desktop' else 0

if remote_app_group_ids:
    remote_app_assignment_count = len([assignment for assignment in assignments if assignment['scope'] in remote_app_group_ids])
else:
    remote_app_assignment_count = assignment_count if preferred_app_group_type == 'remoteapp' else 0

direct_user_assignment_count = len([assignment for assignment in assignments if assignment['principalType'].lower() == 'user'])
group_assignment_count = len([assignment for assignment in assignments if assignment['principalType'].lower() == 'group'])

outputs = {
    'state': state,
    'desktopAssignmentCount': desktop_assignment_count,
    'remoteAppAssignmentCount': remote_app_assignment_count,
    'directUserAssignmentCount': direct_user_assignment_count,
    'groupAssignmentCount': group_assignment_count,
    'assignmentCandidateCount': assignment_count,
    'queriedScopeCount': len(app_group_ids),
    'errors': errors,
    'assignments': assignments,
}

output_path = os.environ.get('AZ_SCRIPTS_OUTPUT_PATH')
if output_path:
    with open(output_path, 'w', encoding='utf-8') as output_file:
        json.dump(outputs, output_file)

print(json.dumps(outputs))
PY
