# 🧠 ChatGPT History Interrogator

A beautiful web interface for exploring and analyzing your ChatGPT conversation history with advanced search, theming, and markdown rendering.

![Interface Preview](https://img.shields.io/badge/Interface-Steel%20Blue%20Theme-5a7a8f?style=for-the-badge)

## ✨ Features

- **🔍 Powerful Search**: Fuzzy search through titles and content with advanced filtering
- **🎨 6 Premium Themes**: Steel Blue (default), Warm Slate, Sage Green, Forest Moss, Deep Ocean, Current
- **💬 Rich Viewer**: Full markdown rendering with syntax highlighting for code blocks
- **🔄 Message Filtering**: View User only, Assistant only, or Both messages
- **📊 Live Stats**: Real-time conversation and message counts
- **🛡️ Privacy First**: 100% local processing - your data never leaves your device

## 🚀 Quick Start

### Get Your ChatGPT Data
1. Go to [ChatGPT Settings](https://chat.openai.com/settings) → Data Controls → Export Data
2. Download your export when ready (up to 24 hours)
3. Extract the ZIP and locate `conversations.json`

### Use the Web Interface
1. **Download** or clone this repository
2. **Open `index.html`** in your web browser
3. **Drag & drop** your `conversations.json` file into the upload area
4. **Start exploring** your conversations!

### Use the Shell Script (Advanced)
```bash
# Make executable
chmod +x chatgpt_interrogator_v0.8.sh

# Run with your export directory
./chatgpt_interrogator_v0.8.sh /path/to/ChatGPT_Export_Directory
🎯 What You Can Do

Search conversations by keywords, titles, or content
Filter messages to see only your questions or ChatGPT's responses
View formatted content with proper headers, code blocks, and links
Switch themes to match your preference
Bulk select conversations for organization
Analyze patterns in your chat history

🛡️ Privacy & Security

Local processing only - no cloud uploads or external requests
Your data stays private - conversations never leave your computer
No tracking - no analytics, cookies, or data collection
Open source - fully auditable code

🔧 Technical Requirements

Modern web browser (Chrome, Firefox, Safari, Edge)
Your ChatGPT conversations.json export file
Optional: Bash shell for advanced script features

📊 Tested With

✅ 2000+ conversations
✅ Large conversation files (200MB+)
✅ All major browsers
✅ Various ChatGPT export formats

🤝 Contributing
Found a bug or have a feature idea? Open an issue or submit a pull request!

Transform your ChatGPT history into searchable, organized insights! 🚀
