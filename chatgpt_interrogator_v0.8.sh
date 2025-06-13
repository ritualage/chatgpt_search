#!/bin/bash

# ChatGPT SQLite Database Parser & Interrogator v0.6
# Purpose: Parse ChatGPT JSON data into SQLite and provide powerful interrogation tools
# Usage: ./chatgpt_interrogator.sh [directory_path]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Default directory or use provided argument
CHAT_DIR="${1:-/home/tuxnuc/Documents/ChatGPT_Exports/ChatGPT_13-06-2025}"
DB_FILE="$CHAT_DIR/chatgpt_conversations.db"

echo -e "${CYAN}🧠 ChatGPT SQLite Database Parser & Interrogator v0.6${NC}"
echo -e "${CYAN}===================================================${NC}"
echo -e "Analyzing directory: ${YELLOW}$CHAT_DIR${NC}"
echo -e "Database file: ${YELLOW}$DB_FILE${NC}\n"

# Check if directory exists and navigate
if [ ! -d "$CHAT_DIR" ]; then
    echo -e "${RED}Error: Directory $CHAT_DIR not found${NC}"
    exit 1
fi

cd "$CHAT_DIR"

# Check for required tools
check_dependencies() {
    local missing_tools=()
    
    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq")
    fi
    
    if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
        missing_tools+=("python3")
    fi
    
    # Test if Python has sqlite3 module
    if ! python3 -c "import sqlite3" 2>/dev/null && ! python -c "import sqlite3" 2>/dev/null; then
        missing_tools+=("python sqlite3 module")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo -e "${RED}Error: Missing required tools: ${missing_tools[*]}${NC}"
        echo -e "${YELLOW}Install with:${NC}"
        echo -e "  Ubuntu/Debian: ${GREEN}sudo apt install jq python3${NC}"
        echo -e "  macOS: ${GREEN}brew install jq python3${NC}"
        exit 1
    fi
    
    # Set Python command
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    else
        PYTHON_CMD="python"
    fi
}

# Check for required files
echo -e "${BLUE}📁 File Structure Analysis${NC}"
echo -e "${BLUE}=========================${NC}"
for file in chat.html conversations.json message_feedback.json shared_conversations.json user.json; do
    if [ -f "$file" ]; then
        size=$(du -h "$file" | cut -f1)
        echo -e "✅ $file (${size})"
    else
        echo -e "❌ $file (missing)"
    fi
done
echo

# Create database schema
create_database_schema() {
    echo -e "${GREEN}🗄️ Creating SQLite database schema...${NC}"
    
    $PYTHON_CMD << 'EOF'
import sqlite3
import sys

try:
    conn = sqlite3.connect('chatgpt_conversations.db')
    cursor = conn.cursor()
    
    # Drop existing tables
    cursor.execute('DROP TABLE IF EXISTS conversations')
    cursor.execute('DROP TABLE IF EXISTS messages')
    cursor.execute('DROP TABLE IF EXISTS tags')
    cursor.execute('DROP TABLE IF EXISTS conversation_tags')
    
    # Create conversations table
    cursor.execute('''
    CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        title TEXT,
        create_time INTEGER,
        create_date TEXT,
        update_time INTEGER,
        update_date TEXT,
        model_slug TEXT,
        conversation_id TEXT,
        gizmo_id TEXT,
        gizmo_type TEXT,
        is_archived INTEGER,
        is_starred INTEGER,
        conversation_origin TEXT,
        message_count INTEGER,
        total_characters INTEGER,
        user_messages INTEGER,
        assistant_messages INTEGER,
        system_messages INTEGER,
        json_size_bytes INTEGER,
        has_code_content INTEGER,
        has_multimodal_content INTEGER,
        category TEXT,
        summary TEXT
    )''')
    
    # Create messages table
    cursor.execute('''
    CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT,
        author_role TEXT,
        content TEXT,
        content_type TEXT,
        language TEXT,
        create_time INTEGER,
        character_count INTEGER,
        word_count INTEGER,
        status TEXT,
        parent_id TEXT,
        has_children INTEGER,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id)
    )''')
    
    # Create tags table
    cursor.execute('''
    CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE,
        category TEXT,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )''')
    
    # Create conversation_tags table
    cursor.execute('''
    CREATE TABLE conversation_tags (
        conversation_id TEXT,
        tag_id INTEGER,
        confidence FLOAT,
        source TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (conversation_id, tag_id),
        FOREIGN KEY (conversation_id) REFERENCES conversations(id),
        FOREIGN KEY (tag_id) REFERENCES tags(id)
    )''')
    
    # Create indexes
    cursor.execute('CREATE INDEX idx_conversations_create_time ON conversations(create_time)')
    cursor.execute('CREATE INDEX idx_conversations_title ON conversations(title)')
    cursor.execute('CREATE INDEX idx_conversations_model ON conversations(model_slug)')
    cursor.execute('CREATE INDEX idx_conversations_message_count ON conversations(message_count)')
    cursor.execute('CREATE INDEX idx_conversations_size ON conversations(total_characters)')
    cursor.execute('CREATE INDEX idx_conversations_category ON conversations(category)')
    cursor.execute('CREATE INDEX idx_messages_conversation_id ON messages(conversation_id)')
    cursor.execute('CREATE INDEX idx_messages_role ON messages(author_role)')
    cursor.execute('CREATE INDEX idx_messages_content ON messages(content)')
    cursor.execute('CREATE INDEX idx_tags_name ON tags(name)')
    cursor.execute('CREATE INDEX idx_tags_category ON tags(category)')
    cursor.execute('CREATE INDEX idx_conversation_tags_tag_id ON conversation_tags(tag_id)')
    
    conn.commit()
    conn.close()
    
    print("Database schema created successfully")
    
except sqlite3.Error as e:
    print(f"SQLite error: {e}", file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
EOF
    
    echo -e "${GREEN}✅ Database schema created${NC}"
}

# Parse JSON data into SQLite - simplified version
parse_json_to_sqlite() {
    echo -e "${GREEN}📊 Parsing JSON data into SQLite database...${NC}"
    echo -e "${BLUE}This may take a few minutes for large datasets...${NC}"
    
    $PYTHON_CMD << 'EOF'
import json
import sqlite3
import sys
from datetime import datetime

def safe_str(value):
    """Safely convert value to string, handling None and special characters"""
    if value is None:
        return ""
    return str(value).replace("'", "''")

try:
    # Load JSON data
    print("Loading JSON data...")
    with open('conversations.json', 'r', encoding='utf-8') as f:
        conversations = json.load(f)
    
    print(f"Found {len(conversations)} conversations")
    
    # Connect to database
    conn = sqlite3.connect('chatgpt_conversations.db')
    cursor = conn.cursor()
    
    processed = 0
    
    for conv in conversations:
        try:
            # Extract basic conversation data
            conv_id = conv.get('id', '')
            title = safe_str(conv.get('title', ''))
            create_time = conv.get('create_time', 0)
            update_time = conv.get('update_time', 0)
            
            # Convert timestamps to readable dates
            create_date = datetime.fromtimestamp(create_time).strftime('%Y-%m-%d %H:%M:%S') if create_time else ''
            update_date = datetime.fromtimestamp(update_time).strftime('%Y-%m-%d %H:%M:%S') if update_time else ''
            
            model_slug = safe_str(conv.get('default_model_slug', ''))
            conversation_id = safe_str(conv.get('conversation_id', ''))
            gizmo_id = safe_str(conv.get('gizmo_id', ''))
            gizmo_type = safe_str(conv.get('gizmo_type', ''))
            is_archived = 1 if conv.get('is_archived', False) else 0
            is_starred = 1 if conv.get('is_starred', False) else 0
            conversation_origin = safe_str(conv.get('conversation_origin', ''))
            
            # Process mapping/messages
            mapping = conv.get('mapping', {})
            message_count = len(mapping)
            json_size = len(json.dumps(conv))
            
            # Count messages by role and calculate total characters
            user_count = 0
            assistant_count = 0
            system_count = 0
            total_chars = 0
            has_code = 0
            has_multimodal = 0
            
            for msg_id, msg_data in mapping.items():
                if not isinstance(msg_data, dict):
                    continue
                    
                message = msg_data.get('message')
                if not message:
                    continue
                    
                author = message.get('author', {})
                role = author.get('role', '')
                content_data = message.get('content', {})
                parts = content_data.get('parts', [])
                content_type = content_data.get('content_type', 'text')
                language = content_data.get('language', '')
                status = message.get('status', '')
                msg_create_time = message.get('create_time', 0)
                
                # Join content parts
                content = ' '.join(str(part) for part in parts if part) if parts else ''
                content = safe_str(content)
                
                char_count = len(content)
                word_count = len(content.split()) if content else 0
                total_chars += char_count
                
                # Count by role
                if role == 'user':
                    user_count += 1
                elif role == 'assistant':
                    assistant_count += 1
                elif role == 'system':
                    system_count += 1
                
                # Check content types
                if content_type == 'code':
                    has_code = 1
                elif content_type not in ['text', 'code', '']:
                    has_multimodal = 1
                
                # Check if message has children
                children = msg_data.get('children', [])
                has_children = 1 if children else 0
                parent_id = safe_str(msg_data.get('parent', ''))
                
                # Insert message
                if content:  # Only insert messages with content
                    cursor.execute('''
                    INSERT OR IGNORE INTO messages 
                    (id, conversation_id, author_role, content, content_type, 
                     language, create_time, character_count, word_count, 
                     status, parent_id, has_children) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ''', (msg_id, conv_id, role, content, content_type, 
                          language, msg_create_time, char_count, word_count,
                          status, parent_id, has_children))
            
            # Insert conversation
            cursor.execute('''
            INSERT OR IGNORE INTO conversations 
            (id, title, create_time, create_date, update_time, update_date,
             model_slug, conversation_id, gizmo_id, gizmo_type, is_archived,
             is_starred, conversation_origin, message_count, total_characters,
             user_messages, assistant_messages, system_messages, json_size_bytes,
             has_code_content, has_multimodal_content)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (conv_id, title, create_time, create_date, update_time, update_date,
                  model_slug, conversation_id, gizmo_id, gizmo_type, is_archived,
                  is_starred, conversation_origin, message_count, total_chars,
                  user_count, assistant_count, system_count, json_size,
                  has_code, has_multimodal))
            
            processed += 1
            if processed % 100 == 0:
                print(f"Processed {processed} conversations...")
                conn.commit()
                
        except Exception as e:
            print(f"Error processing conversation {conv.get('id', 'unknown')}: {e}")
            continue
    
    conn.commit()
    
    # Get final statistics
    cursor.execute('SELECT COUNT(*) FROM conversations')
    conv_count = cursor.fetchone()[0]
    
    cursor.execute('SELECT COUNT(*) FROM messages')
    msg_count = cursor.fetchone()[0]
    
    conn.close()
    
    print(f"\nParsing complete!")
    print(f"Conversations: {conv_count}")
    print(f"Messages: {msg_count}")
    
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
EOF
}

# Database query functions
db_stats() {
    echo -e "${CYAN}📊 Database Statistics${NC}"
    echo "====================="
    
    $PYTHON_CMD << 'EOF'
import sqlite3

conn = sqlite3.connect('chatgpt_conversations.db')
cursor = conn.cursor()

print("Basic Statistics:")
print("-" * 40)

# Basic counts
queries = [
    ("Total Conversations", "SELECT COUNT(*) FROM conversations"),
    ("Total Messages", "SELECT COUNT(*) FROM messages"),
    ("Conversations with Titles", "SELECT COUNT(*) FROM conversations WHERE title != ''"),
    ("Average Messages/Conversation", "SELECT ROUND(AVG(message_count), 1) FROM conversations"),
    ("Average Characters/Conversation", "SELECT ROUND(AVG(total_characters), 0) FROM conversations"),
    ("Total Characters (All)", "SELECT SUM(total_characters) FROM conversations")
]

for label, query in queries:
    cursor.execute(query)
    result = cursor.fetchone()[0]
    print(f"{label:.<30} {result}")

print("\nDate Range:")
print("-" * 40)

cursor.execute("SELECT MIN(create_date), MAX(create_date) FROM conversations WHERE create_date != ''")
first, last = cursor.fetchone()
print(f"First conversation: {first}")
print(f"Last conversation: {last}")

print("\nActivity by Year:")
print("-" * 40)

cursor.execute("""
SELECT strftime('%Y', create_date) as year, COUNT(*) as count 
FROM conversations 
WHERE create_date != ''
GROUP BY strftime('%Y', create_date)
ORDER BY year
""")

for year, count in cursor.fetchall():
    print(f"{year}: {count} conversations")

conn.close()
EOF
}

db_search_conversations() {
    local keyword="$1"
    local limit="${2:-20}"
    local order="${3:-newest}"
    local search_type="${4:-title}"  # title, content, both
    
    if [ -z "$keyword" ]; then
        echo -e "${RED}Usage: db_search_conversations \"keyword\" [limit] [newest|oldest|largest|smallest] [title|content|both]${NC}"
        return 1
    fi
    
    echo -e "${CYAN}🔍 Search Results for: '$keyword' (${order}, limit: $limit, searching: $search_type)${NC}"
    echo "==========================================================================="
    
    $PYTHON_CMD << EOF
import sqlite3

conn = sqlite3.connect('chatgpt_conversations.db')
cursor = conn.cursor()

order_clause = {
    'oldest': 'ORDER BY create_time ASC',
    'largest': 'ORDER BY total_characters DESC', 
    'smallest': 'ORDER BY total_characters ASC',
    'newest': 'ORDER BY create_time DESC'
}.get('$order', 'ORDER BY create_time DESC')

# Different search types
if '$search_type' == 'title':
    where_clause = "WHERE title LIKE ?"
    search_param = '%$keyword%'
elif '$search_type' == 'content':
    where_clause = """WHERE id IN (
        SELECT DISTINCT conversation_id 
        FROM messages 
        WHERE content LIKE ?
    )"""
    search_param = '%$keyword%'
elif '$search_type' == 'both':
    where_clause = """WHERE title LIKE ? OR id IN (
        SELECT DISTINCT conversation_id 
        FROM messages 
        WHERE content LIKE ?
    )"""
    search_param = ('%$keyword%', '%$keyword%')
else:
    where_clause = "WHERE title LIKE ?"
    search_param = '%$keyword%'

query = f'''
SELECT 
    substr(id, 1, 8) as ID,
    substr(create_date, 1, 10) as Date,
    CASE 
        WHEN length(title) > 45 THEN substr(title, 1, 42) || '...'
        ELSE title 
    END as Title,
    message_count as Msgs,
    total_characters as Chars,
    CASE 
        WHEN total_characters > 10000 THEN 'XL'
        WHEN total_characters > 5000 THEN 'L'
        WHEN total_characters > 2000 THEN 'M'
        WHEN total_characters > 500 THEN 'S'
        ELSE 'XS'
    END as Size
FROM conversations 
{where_clause}
{order_clause}
LIMIT $limit
'''

if '$search_type' == 'both':
    cursor.execute(query, search_param)
else:
    cursor.execute(query, (search_param,))

results = cursor.fetchall()

if results:
    print(f"{'ID':<10} {'Date':<12} {'Title':<45} {'Msgs':<5} {'Chars':<8} {'Size'}")
    print("-" * 90)
    for row in results:
        print(f"{row[0]:<10} {row[1]:<12} {row[2]:<45} {row[3]:<5} {row[4]:<8} {row[5]}")
    
    # Show which conversations have keyword in content vs title
    if '$search_type' == 'both':
        print("\nBreakdown:")
        cursor.execute("SELECT COUNT(*) FROM conversations WHERE title LIKE ?", ('%$keyword%',))
        title_count = cursor.fetchone()[0]
        
        cursor.execute("""
        SELECT COUNT(DISTINCT conversation_id) 
        FROM messages 
        WHERE content LIKE ?
        """, ('%$keyword%',))
        content_count = cursor.fetchone()[0]
        
        print(f"  In titles: {title_count}")
        print(f"  In content: {content_count}")
else:
    print("No conversations found")
    
    # Suggest alternative searches
    print(f"\nSuggestions:")
    print(f"  • Try searching content: db_search_conversations '$keyword' 20 newest content")
    print(f"  • Try searching both: db_search_conversations '$keyword' 20 newest both")
    print(f"  • Try partial word: db_search_conversations 'para' 20 newest both")

# Get total count for current search type
if '$search_type' == 'title':
    cursor.execute("SELECT COUNT(*) FROM conversations WHERE title LIKE ?", ('%$keyword%',))
elif '$search_type' == 'content':
    cursor.execute("SELECT COUNT(DISTINCT conversation_id) FROM messages WHERE content LIKE ?", ('%$keyword%',))
elif '$search_type' == 'both':
    cursor.execute("""
    SELECT COUNT(*) FROM conversations 
    WHERE title LIKE ? OR id IN (
        SELECT DISTINCT conversation_id FROM messages WHERE content LIKE ?
    )""", ('%$keyword%', '%$keyword%'))

total = cursor.fetchone()[0]
print(f"\nFound {total} total conversations containing '$keyword' in $search_type")

conn.close()
EOF
}

db_get_conversation() {
    local id="$1"
    
    if [ -z "$id" ]; then
        echo -e "${RED}Usage: db_get_conversation [partial-id]${NC}"
        return 1
    fi
    
    echo -e "${CYAN}📄 Conversation Details${NC}"
    echo "======================"
    
    $PYTHON_CMD << EOF
import sqlite3
import sys

try:
    conn = sqlite3.connect('chatgpt_conversations.db')
    cursor = conn.cursor()

    # First try exact match
    cursor.execute('''
    SELECT 
        id, title, create_date, update_date, model_slug, message_count,
        total_characters, user_messages, assistant_messages,
        CASE 
            WHEN total_characters > 10000 THEN 'Extra Large'
            WHEN total_characters > 5000 THEN 'Large'
            WHEN total_characters > 2000 THEN 'Medium'
            WHEN total_characters > 500 THEN 'Small'
            ELSE 'Extra Small'
        END as size_category
    FROM conversations 
    WHERE id = ?
    ''', ('$id',))
    
    result = cursor.fetchone()
    
    # If no exact match, try partial match
    if not result:
        cursor.execute('''
        SELECT 
            id, title, create_date, update_date, model_slug, message_count,
            total_characters, user_messages, assistant_messages,
            CASE 
                WHEN total_characters > 10000 THEN 'Extra Large'
                WHEN total_characters > 5000 THEN 'Large'
                WHEN total_characters > 2000 THEN 'Medium'
                WHEN total_characters > 500 THEN 'Small'
                ELSE 'Extra Small'
            END as size_category
        FROM conversations 
        WHERE id LIKE ?
        LIMIT 1
        ''', ('$id%',))
        result = cursor.fetchone()
    
    if result:
        labels = ['Full ID', 'Title', 'Created', 'Updated', 'Model', 'Messages', 
                  'Characters', 'User Msgs', 'Assistant Msgs', 'Size Category']
        
        for label, value in zip(labels, result):
            print(f"{label:.<20} {value}")
            
        # Show message count by role
        cursor.execute('''
        SELECT author_role, COUNT(*) as count
        FROM messages
        WHERE conversation_id = ?
        GROUP BY author_role
        ''', (result[0],))
        
        print("\nMessage Count by Role:")
        print("-" * 20)
        for role, count in cursor.fetchall():
            print(f"{role:.<15} {count}")
    else:
        print(f"No conversation found with ID: $id")
        print("\nTip: Try using the first 8 characters of the ID")
        print("     Example: If ID is '684a0e6f-1234-5678', use '684a0e6f'")

except sqlite3.Error as e:
    print(f"Database error: {e}", file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
finally:
    conn.close()
EOF
}

db_extract_messages() {
    local id="$1"
    local role_filter="${2:-all}"
    
    if [ -z "$id" ]; then
        echo -e "${RED}Usage: db_extract_messages [partial-id] [all|user|assistant]${NC}"
        return 1
    fi
    
    echo -e "${CYAN}💬 Extracting Messages${NC}"
    echo "======================"
    
    $PYTHON_CMD << EOF
import sqlite3

conn = sqlite3.connect('chatgpt_conversations.db')
cursor = conn.cursor()

# Get conversation title
cursor.execute('SELECT title FROM conversations WHERE id LIKE ? LIMIT 1', ('$id%',))
result = cursor.fetchone()
if not result:
    print("No conversation found with that ID")
    exit(1)

title = result[0] or "Untitled"
print(f"Conversation: {title}")
print("=" * 60)

# Get messages
role_clause = ""
if '$role_filter' != 'all':
    role_clause = "AND author_role = '$role_filter'"

cursor.execute(f'''
SELECT 
    author_role,
    substr(content, 1, 200) || CASE WHEN length(content) > 200 THEN '...' ELSE '' END as content
FROM messages 
WHERE conversation_id LIKE ? {role_clause}
ORDER BY create_time
''', ('$id%',))

for role, content in cursor.fetchall():
    print(f"[{role.upper()}]: {content}")
    print()

conn.close()
EOF
}

db_search_content() {
    local keyword="$1"
    local limit="${2:-10}"
    
    if [ -z "$keyword" ]; then
        echo -e "${RED}Usage: db_search_content \"keyword\" [limit]${NC}"
        return 1
    fi
    
    echo -e "${CYAN}📝 Content Search Results for: '$keyword' (limit: $limit)${NC}"
    echo "================================================================"
    
    $PYTHON_CMD << EOF
import sqlite3

conn = sqlite3.connect('chatgpt_conversations.db')
cursor = conn.cursor()

# Find conversations with keyword in message content
query = '''
SELECT DISTINCT
    c.id,
    substr(c.id, 1, 8) as short_id,
    substr(c.create_date, 1, 10) as date,
    CASE 
        WHEN length(c.title) > 40 THEN substr(c.title, 1, 37) || '...'
        ELSE c.title 
    END as title,
    c.total_characters,
    COUNT(m.id) as matching_messages
FROM conversations c
JOIN messages m ON c.id = m.conversation_id
WHERE m.content LIKE ?
GROUP BY c.id
ORDER BY c.create_time DESC
LIMIT ?
'''

search_term = '%$keyword%'
cursor.execute(query, (search_term, $limit))
results = cursor.fetchall()

if results:
    print(f"{'ID':<10} {'Date':<12} {'Title':<40} {'Chars':<8} {'Matches'}")
    print("-" * 80)
    for row in results:
        print(f"{row[1]:<10} {row[2]:<12} {row[3]:<40} {row[4]:<8} {row[5]}")
    
    print(f"\nShowing {len(results)} conversations with '$keyword' in message content")
    
    # Show sample messages
    print(f"\nSample messages containing '$keyword':")
    print("-" * 60)
    
    cursor.execute('''
    SELECT 
        c.title,
        m.author_role,
        substr(m.content, 1, 150) || '...' as preview
    FROM messages m
    JOIN conversations c ON m.conversation_id = c.id
    WHERE m.content LIKE ?
    ORDER BY m.character_count DESC
    LIMIT 3
    ''', (search_term,))
    
    for title, role, preview in cursor.fetchall():
        title_short = title[:30] + '...' if len(title) > 30 else title
        print(f"{title_short}")
        print(f"[{role.upper()}]: {preview}")
        print()
        
else:
    print(f"No messages found containing '$keyword'")
    print("\nTip: Try different variations or check spelling")

conn.close()
EOF
}

db_view_chat() {
    local id="$1"
    
    if [ -z "$id" ]; then
        echo -e "${RED}Usage: db_view_chat [partial-id]${NC}"
        return 1
    fi
    
    echo -e "${CYAN}💬 Viewing Chat Content${NC}"
    echo "======================"
    
    $PYTHON_CMD << EOF
import sqlite3
import sys
from datetime import datetime

try:
    conn = sqlite3.connect('chatgpt_conversations.db')
    cursor = conn.cursor()

    # Get conversation details
    cursor.execute('''
    SELECT id, title, create_date, model_slug
    FROM conversations 
    WHERE id LIKE ?
    LIMIT 1
    ''', ('$id%',))
    
    conv = cursor.fetchone()
    if not conv:
        print(f"No conversation found with ID: $id")
        print("\nTip: Try using the first 8 characters of the ID")
        sys.exit(1)
        
    conv_id, title, create_date, model = conv
    print(f"Title: {title}")
    print(f"Date: {create_date}")
    print(f"Model: {model}")
    print("=" * 80)
    
    # Get all messages in chronological order
    cursor.execute('''
    SELECT 
        author_role,
        content,
        create_time
    FROM messages 
    WHERE conversation_id = ?
    ORDER BY create_time
    ''', (conv_id,))
    
    messages = cursor.fetchall()
    if not messages:
        print("No messages found in this conversation")
        sys.exit(1)
    
    # Print messages with timestamps
    for role, content, timestamp in messages:
        # Convert timestamp to readable format
        time_str = datetime.fromtimestamp(timestamp).strftime('%Y-%m-%d %H:%M:%S') if timestamp else 'Unknown'
        
        # Print message header
        print(f"\n[{role.upper()}] - {time_str}")
        print("-" * 80)
        
        # Print message content with proper formatting
        print(content)
        print("=" * 80)

except sqlite3.Error as e:
    print(f"Database error: {e}", file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
finally:
    conn.close()
EOF
}

# New function to select and process ranges of conversations
db_process_range() {
    local start_id="$1"
    local end_id="$2"
    local action="$3"
    
    if [ -z "$start_id" ] || [ -z "$end_id" ] || [ -z "$action" ]; then
        echo -e "${RED}Usage: db_process_range [start_id] [end_id] [action]${NC}"
        echo -e "Actions: view, export, tag, summarize"
        return 1
    fi
    
    $PYTHON_CMD << EOF
import sqlite3
import sys
from datetime import datetime

try:
    conn = sqlite3.connect('chatgpt_conversations.db')
    cursor = conn.cursor()
    
    # Get conversations in range
    cursor.execute('''
    SELECT id, title, create_date, message_count
    FROM conversations 
    WHERE id BETWEEN ? AND ?
    ORDER BY create_time
    ''', ('$start_id', '$end_id'))
    
    conversations = cursor.fetchall()
    if not conversations:
        print(f"No conversations found between $start_id and $end_id")
        sys.exit(1)
    
    print(f"Found {len(conversations)} conversations in range")
    print("=" * 80)
    
    # Process based on action
    if '$action' == 'view':
        for conv_id, title, date, msg_count in conversations:
            print(f"\nID: {conv_id}")
            print(f"Title: {title}")
            print(f"Date: {date}")
            print(f"Messages: {msg_count}")
            print("-" * 80)
            
            # Get messages
            cursor.execute('''
            SELECT author_role, content, create_time
            FROM messages 
            WHERE conversation_id = ?
            ORDER BY create_time
            ''', (conv_id,))
            
            for role, content, timestamp in cursor.fetchall():
                time_str = datetime.fromtimestamp(timestamp).strftime('%Y-%m-%d %H:%M:%S') if timestamp else 'Unknown'
                print(f"\n[{role.upper()}] - {time_str}")
                print("-" * 40)
                print(content)
                print("=" * 80)
    
    elif '$action' == 'export':
        import json
        from pathlib import Path
        
        export_dir = Path('chat_exports')
        export_dir.mkdir(exist_ok=True)
        
        for conv_id, title, date, msg_count in conversations:
            # Get full conversation data
            cursor.execute('''
            SELECT 
                c.*,
                json_group_array(
                    json_object(
                        'role', m.author_role,
                        'content', m.content,
                        'timestamp', m.create_time
                    )
                ) as messages
            FROM conversations c
            LEFT JOIN messages m ON c.id = m.conversation_id
            WHERE c.id = ?
            GROUP BY c.id
            ''', (conv_id,))
            
            conv_data = cursor.fetchone()
            if conv_data:
                # Convert to dict
                conv_dict = dict(zip([col[0] for col in cursor.description], conv_data))
                conv_dict['messages'] = json.loads(conv_dict['messages'])
                
                # Save to file
                safe_title = "".join(c for c in title if c.isalnum() or c in (' ', '-', '_')).strip()
                filename = f"{conv_id}_{safe_title}.json"
                with open(export_dir / filename, 'w', encoding='utf-8') as f:
                    json.dump(conv_dict, f, indent=2, ensure_ascii=False)
                
                print(f"Exported: {filename}")
    
    elif '$action' == 'tag':
        # TODO: Implement AI tagging using local LLM or OpenAI
        print("Tagging functionality coming soon!")
        print("This will use AI to automatically tag conversations based on content")
    
    elif '$action' == 'summarize':
        # TODO: Implement AI summarization
        print("Summarization functionality coming soon!")
        print("This will generate concise summaries of conversation content")
    
    else:
        print(f"Unknown action: $action")

except sqlite3.Error as e:
    print(f"Database error: {e}", file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
finally:
    conn.close()
EOF
}

# Interactive menu
interactive_database_menu() {
    while true; do
        echo -e "\n${CYAN}🗄️ SQLite Database Interrogator v0.8${NC}"
        echo -e "${CYAN}================================${NC}"
        echo
        echo "1. 📊 Show database statistics"
        echo "2. 🔍 Search conversations by title keyword"
        echo "3. 📝 Search conversations by content keyword"
        echo "4. 🔍 Search both titles and content"
        echo "5. 📄 Get conversation details by ID"
        echo "6. 💬 Extract messages from conversation"
        echo "7. 📖 View full chat content"
        echo "8. 📑 Process range of conversations"
        echo "9. 🏷️  Manage tags and categories"
        echo "10. 📤 Export conversations"
        echo "11. 🔄 Re-parse JSON data (if updated)"
        echo "12. ❌ Exit"
        echo
        read -p "Select option (1-12): " choice
        
        case $choice in
            1)
                db_stats
                ;;
            2)
                echo -e "${BLUE}Searching conversation titles only${NC}"
                read -p "Enter keyword: " keyword
                read -p "Number of results to show: " limit
                read -p "Order [newest/oldest/largest/smallest]: " order
                if [ -n "$keyword" ]; then
                    db_search_conversations "$keyword" "${limit:-10}" "${order:-newest}" "title"
                fi
                ;;
            3)
                echo -e "${BLUE}Searching message content only${NC}"
                read -p "Enter keyword: " keyword
                read -p "Number of results to show: " limit
                if [ -n "$keyword" ]; then
                    db_search_content "$keyword" "${limit:-10}"
                fi
                ;;
            4)
                echo -e "${BLUE}Searching both titles and message content${NC}"
                read -p "Enter keyword: " keyword
                read -p "Number of results to show: " limit
                read -p "Order [newest/oldest/largest/smallest]: " order
                if [ -n "$keyword" ]; then
                    db_search_conversations "$keyword" "${limit:-10}" "${order:-newest}" "both"
                fi
                ;;
            5)
                read -p "Enter conversation ID (8 chars or partial): " id
                if [ -n "$id" ]; then
                    db_get_conversation "$id"
                fi
                ;;
            6)
                read -p "Enter conversation ID: " id
                read -p "Filter by role [all/user/assistant]: " role
                if [ -n "$id" ]; then
                    db_extract_messages "$id" "${role:-all}"
                fi
                ;;
            7)
                read -p "Enter conversation ID (8 chars or partial): " id
                if [ -n "$id" ]; then
                    db_view_chat "$id"
                fi
                ;;
            8)
                echo -e "${BLUE}Process range of conversations${NC}"
                read -p "Enter start ID: " start_id
                read -p "Enter end ID: " end_id
                echo "Actions:"
                echo "  view   - View all conversations in range"
                echo "  export - Export conversations to JSON"
                echo "  tag    - Tag conversations (coming soon)"
                echo "  summarize - Generate summaries (coming soon)"
                read -p "Select action: " action
                if [ -n "$start_id" ] && [ -n "$end_id" ] && [ -n "$action" ]; then
                    db_process_range "$start_id" "$end_id" "$action"
                fi
                ;;
            9)
                echo -e "${YELLOW}Tag management coming in next version!${NC}"
                echo "This will include:"
                echo "  • AI-powered automatic tagging"
                echo "  • Manual tag management"
                echo "  • Category organization"
                echo "  • Tag-based search and filtering"
                ;;
            10)
                echo -e "${BLUE}Export conversations${NC}"
                read -p "Enter conversation ID(s) or 'all': " ids
                read -p "Format [json/markdown/text]: " format
                if [ -n "$ids" ] && [ -n "$format" ]; then
                    if [ "$ids" = "all" ]; then
                        db_process_range "00000000" "ffffffff" "export"
                    else
                        # TODO: Implement single/multiple export
                        echo "Export functionality coming soon!"
                    fi
                fi
                ;;
            11)
                echo -e "${YELLOW}Re-parsing JSON data...${NC}"
                create_database_schema
                parse_json_to_sqlite
                ;;
            12)
                echo -e "${GREEN}Database functions remain available in shell!${NC}"
                break
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                ;;
        esac
    done
}

# Main execution
main() {
    check_dependencies
    
    # Check if database exists and is recent
    if [ -f "$DB_FILE" ]; then
        local json_newer=$(find "conversations.json" -newer "$DB_FILE" 2>/dev/null | wc -l)
        
        if [ "$json_newer" -gt 0 ]; then
            echo -e "${YELLOW}🔄 JSON file is newer than database. Re-parsing...${NC}"
            create_database_schema
            parse_json_to_sqlite
        else
            echo -e "${GREEN}✅ Using existing database: ${DB_FILE}${NC}"
            local conv_count=$($PYTHON_CMD -c "import sqlite3; conn = sqlite3.connect('$DB_FILE'); print(conn.execute('SELECT COUNT(*) FROM conversations').fetchone()[0]); conn.close()" 2>/dev/null || echo "0")
            echo -e "  📊 Contains: ${YELLOW}$conv_count conversations${NC}"
        fi
    else
        echo -e "${YELLOW}🆕 Creating new database...${NC}"
        create_database_schema
        parse_json_to_sqlite
    fi
    
    # Export functions for shell use
    export -f db_stats db_search_conversations db_get_conversation db_extract_messages db_search_content db_view_chat db_process_range
    export DB_FILE
    
    echo -e "\n${BLUE}🛠️ Available Database Functions:${NC}"
    echo -e "  • ${GREEN}db_search_conversations \"paradox\" 10 newest title${NC} - Search titles only"
    echo -e "  • ${GREEN}db_search_conversations \"paradox\" 10 newest both${NC} - Search titles + content"
    echo -e "  • ${GREEN}db_search_content \"paradox\" 10${NC} - Search message content with samples"
    echo -e "  • ${GREEN}db_get_conversation a1b2c3d4${NC} - Get detailed conversation info"
    echo -e "  • ${GREEN}db_extract_messages a1b2c3d4${NC} - Extract conversation messages"
    echo -e "  • ${GREEN}db_stats${NC} - Show database statistics"
    
    echo -e "\n${YELLOW}Example: Find 'paradox' in both titles and content:${NC}"
    echo -e "${CYAN}db_search_conversations \"paradox\" 20 newest both${NC}"
    
    echo -e "\n${YELLOW}Example: Search content only with message samples:${NC}"
    echo -e "${CYAN}db_search_content \"investors paradox\" 10${NC}"
    
    echo -e "\n${YELLOW}Start the interactive database menu? (y/n)${NC}"
    read -p "> " start_menu
    
    if [[ $start_menu =~ ^[Yy] ]]; then
        interactive_database_menu
    else
        echo -e "\n${GREEN}All database functions are now available!${NC}"
        echo -e "${BLUE}Try: db_search_conversations \"paradox\"${NC}"
    fi
}

# Run main function
main "$@"