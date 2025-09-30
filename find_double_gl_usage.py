#!/usr/bin/env python3
# find_double_gl_usage.py
import subprocess, os, csv, shlex

# patterns to search for (extended regex)
patterns = [
    r'glUniformMatrix[0-9]*dv',
    r'glUniform[^(]*dv',
    r'glVertex[^(]*dv',
    r'glVertexAttrib(3|4)dv',
    r'glDrawArrays?Instanced?dv',
    r'glm::d(mat|vec|quat)',
    r'\bdvec[0-9]\b',
    r'\bdmat[0-9]\b',
    r'\bdouble\b'
]

pattern = '|'.join(patterns)

def run_in(path):
    cmd = ['grep', '-RInE', pattern, '--exclude-dir=.git', '--exclude-dir=build', '.']
    p = subprocess.Popen(cmd, cwd=path, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    out, _ = p.communicate()
    return out.splitlines()

def read_submodules():
    submods = []
    if os.path.exists('.gitmodules'):
        with open('.gitmodules','r') as f:
            for line in f:
                line=line.strip()
                if line.startswith('path ='):
                    submods.append(line.split('=',1)[1].strip())
    return submods

def main():
    repos = ['.'] + read_submodules()
    rows = []
    for r in repos:
        print(f"Scanning {r} ...")
        lines = run_in(r)
        for L in lines:
            # grep returns ./path/file:line:content (when run inside submodule, prefix may vary).
            # Normalize path
            try:
                file_and_rest = L.split(':',2)
                filepath = file_and_rest[0]
                lineno = file_and_rest[1]
                content = file_and_rest[2] if len(file_and_rest)>2 else ''
                absrepo = os.path.abspath(r)
                rows.append([r, filepath, lineno, content.strip()])
            except Exception as e:
                pass

    outcsv = 'double_gl_report.csv'
    with open(outcsv,'w',newline='') as f:
        w = csv.writer(f)
        w.writerow(['repo','file','line','snippet'])
        for row in rows:
            w.writerow(row)
    print(f"Report saved to {outcsv} ({len(rows)} matches)")

if __name__=='__main__':
    main()
