import re

# The URL you provided
DIFF_URL = "https://github.com/OpenSpace/OpenSpace/compare/master...feature/applesilicon.diff"

def parse_diff(diff_text):
    changes = []
    current_file = None
    
    # Regex to identify file definition lines
    file_pattern = re.compile(r'^\+\+\+ b/(.*)$')
    
    # Iterate through lines
    lines = diff_text.split('\n')
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Detect File Path
        if line.startswith('+++ b/'):
            current_file = file_pattern.match(line).group(1)
            i += 1
            continue
            
        # Detect Hunk Header (starts with @@)
        if line.startswith('@@ '):
            i += 1
            
            # Start collecting a block of changes
            find_block = []
            replace_block = []
            
            # Process lines inside a hunk
            while i < len(lines):
                sub_line = lines[i]
                
                # Stop if we hit the next file or hunk
                if sub_line.startswith('diff --git') or sub_line.startswith('@@ '):
                    break
                
                if sub_line.startswith('-'):
                    find_block.append(sub_line[1:]) # Remove the leading '-'
                elif sub_line.startswith('+'):
                    replace_block.append(sub_line[1:]) # Remove the leading '+'
                elif sub_line.startswith(' '):
                    # Context line: If we have pending blocks, save them and reset
                    # This handles cases where one hunk has multiple separate changes
                    if find_block or replace_block:
                        changes.append({
                            'file': current_file,
                            'find': '\n'.join(find_block),
                            'replace': '\n'.join(replace_block)
                        })
                        find_block = []
                        replace_block = []
                
                i += 1
            
            # Append any remaining block at end of hunk
            if find_block or replace_block:
                changes.append({
                    'file': current_file,
                    'find': '\n'.join(find_block),
                    'replace': '\n'.join(replace_block)
                })
            
            continue
            
        i += 1
        
    return changes

def main():
    local_file = "applesilicon.diff.txt"
    print(f"Reading from {local_file}...")
    try:
        with open(local_file, "r", encoding="utf-8") as f:
            content = f.read()
            
        data = parse_diff(content)
        
        print(f"\nFound {len(data)} replacement operations:\n")
        
        for idx, item in enumerate(data, 1):
            print(f"--- Operation {idx} ---")
            print(f"FILE: {item['file']}")
            print("FIND:")
            print(f"'{item['find']}'")
            print("REPLACE WITH:")
            print(f"'{item['replace']}'")
            print("-" * 40 + "\n")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
