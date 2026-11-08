"""Scoped AST guard for migrated production mail paths; stdlib only.
REPORT-CARD >> features/mail-consolidation.feature
"""
import ast
from pathlib import Path

CALLERS=('bin/freellmask-mail','bin/keelynet-energy-mailer','bin/mail-free-energy-analysis','shared/aimeat_mail.py')

def violations(source, name):
    tree=ast.parse(source);problems=[]
    for fn in [n for n in ast.walk(tree) if isinstance(n,ast.FunctionDef)]:
        endpoint = any(isinstance(n,ast.Constant) and isinstance(n.value,str)
                       and any(token in n.value for token in ('api.agentmail.to','/messages/send','/reply'))
                       for n in ast.walk(fn))
        for node in ast.walk(fn):
            if isinstance(node,ast.Call):
                func=node.func;called=func.attr if isinstance(func,ast.Attribute) else func.id if isinstance(func,ast.Name) else ''
                if called in {'Request','urlopen','post'} and (fn.name in {'send_email','send_source_email','send_inbox_reply'} or (endpoint and fn.name != 'http')):
                    problems.append((node.lineno,'direct transport in sending function'))
                if called in {'md_to_inner_html','wrap_email_html','canonical_md_to_html'} or (fn.name=='make_pdf_b64' and called=='md_to_html'):problems.append((node.lineno,'email inner renderer outside canonical module'))
            if isinstance(node,ast.Constant) and isinstance(node.value,str):
                if '<!doctype html' in node.value.lower() or '<html' in node.value.lower():
                    problems.append((node.lineno,'caller-owned complete HTML document'))
            target=node.target if isinstance(node,ast.AugAssign) else node.targets[0] if isinstance(node,ast.Assign) and len(node.targets)==1 else None
            if isinstance(target,ast.Subscript) and isinstance(target.slice,ast.Constant) and target.slice.value=='html':
                value=node.value
                if isinstance(node,ast.AugAssign) or isinstance(value,ast.BinOp):
                    problems.append((node.lineno,'HTML appended after rendering'))
    return [(name,line,reason) for line,reason in problems]

def check(root):
    result=[problem for name in CALLERS for problem in violations((Path(root)/name).read_text(),name)]
    for name in ('shared/format_email.py','shared/agentmail_send.py'):
        seen=set()
        for node in ast.parse((Path(root)/name).read_text()).body:
            if isinstance(node,(ast.FunctionDef,ast.ClassDef)):
                if node.name in seen: result.append((name,node.lineno,'duplicate canonical definition: '+node.name))
                seen.add(node.name)
    return result

if __name__=='__main__':
    import sys
    problems=check(Path(sys.argv[1]) if len(sys.argv)>1 else Path(__file__).resolve().parent.parent)
    for name,line,reason in problems:print(f'{name}:{line}: {reason}')
    raise SystemExit(bool(problems))
