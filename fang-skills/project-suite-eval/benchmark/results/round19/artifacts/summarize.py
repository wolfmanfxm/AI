import json, glob, os, re, sys

base = '/Users/fangxiangming/.cache/ps-eval/round19/results'
for p in sorted(glob.glob(os.path.join(base, 'out', '*.json'))):
    name = os.path.basename(p)[:-5]
    try:
        d = json.load(open(p))
    except Exception as e:
        print(f'## {name}: INVALID/EMPTY ({e})'); continue
    res = d.get('result') or ''
    skills = re.findall(r'Skill 调用[:：]\s*([^\n（(]*)（([^）)]*)）', res)
    agent = 'Agent=YES' if '派生（是）' in res or '用 Agent/Task 派生（是' in res else ''
    qa = 'QA NOT INDEPENDENT' if 'QA NOT INDEPENDENT' in res else ('Independent QA' if 'Independent QA' in res else '')
    usage = d.get('modelUsage', {})
    tok = sum(v.get('inputTokens',0) for v in usage.values())
    out = sum(v.get('outputTokens',0) for v in usage.values())
    subs = (d.get('subagent_stats') or {}).get('spawned')
    print(f'## {name} | session={d.get("session_id")} | turns={d.get("num_turns")} | in={tok} out={out} | subagents={subs} | denials={len(d.get("permission_denials") or [])}')
    print('   skill_reports:', skills)
    print('   flags:', agent, qa)
    print('   head:', res[:160].replace('\n', ' '))
    print()
