# 🧠 ChatGPT History Interrogator

A beautiful, powerful web interface for exploring and analyzing your ChatGPT conversation history. Transform your exported ChatGPT data into searchable, organized insights with advanced filtering, theming, and analysis tools.

![Steel Blue Theme](https://img.shields.io/badge/Interface-Steel%20Blue%20Theme-5a7a8f?style=for-the-badge) ![Privacy First](https://img.shields.io/badge/Privacy-100%25%20Local-green?style=for-the-badge) ![No Dependencies](https://img.shields.io/badge/Dependencies-None-blue?style=for-the-badge)

## ✨ Current Features

### 🔍 **Powerful Search Engine**
- **Fuzzy search** through conversation titles and content with instant results
- **Advanced filtering**: Title-only, Content-only, or Combined search modes
- **Smart sorting**: Newest, Oldest, Most Relevant, or Longest conversations
- **Real-time search** with dynamic results counter
- **Flexible result limits** (25, 50, 100, or All results)

### 🎨 **Beautiful Theme System**
- **6 Premium Themes**: Steel Blue (default), Warm Slate, Sage Green, Forest Moss, Deep Ocean, Current
- **Persistent theme selection** - your choice is remembered across sessions
- **Professional color palettes** designed for technical interfaces
- **Instant theme switching** with smooth transitions

### 💬 **Rich Conversation Viewer**
- **Full markdown rendering** - Headers (# ## ### ####), **bold text**, `code blocks`, lists, links
- **Syntax highlighting** for code blocks with language detection
- **Message filtering** - View User only, Assistant only, or Both messages
- **Interactive modal interface** for focused reading and analysis
- **XSS-safe rendering** with security protection

### 📊 **Live Analytics Dashboard**
- **Real-time statistics** - Total conversations, messages, date ranges
- **Dynamic search results counter** showing filtered conversation counts
- **Bulk selection tools** for conversation management
- **Usage pattern insights** with conversation timeline analysis

### 🛠️ **Advanced Organization Framework**
- **Collections** - Bundle related conversations (UI ready)
- **Groups** - Named organization system (UI ready)
- **Tags** - Flexible labeling and categorization (UI ready)
- **Export capabilities** - Multi-format output framework (UI ready)

### 🛡️ **Privacy & Security**
- **100% Local Processing** - Your data never leaves your computer
- **No cloud uploads** - All analysis happens on your device
- **XSS Protection** - Safe HTML rendering prevents code injection
- **Input sanitization** - All user inputs are validated and cleaned
- **No tracking** - No analytics, cookies, or external requests

## 🚀 Quick Start

### Prerequisites
- Modern web browser (Chrome, Firefox, Safari, Edge)
- Your ChatGPT conversation export file (`conversations.json`)

### Getting Your ChatGPT Data
1. Go to [ChatGPT Settings](https://chat.openai.com/settings) → **Data Controls** → **Export Data**
2. Request your data export (may take up to 24 hours)
3. Download and extract the ZIP file
4. Locate `conversations.json` in the extracted folder

### Using the Web Interface
1. **Download** or clone this repository
2. **Open `index.html`** in your web browser
3. **Load your data**: 
   - Drag & drop your `conversations.json` file into the upload area
   - Or click to browse and select the file
4. **Start exploring** your conversations with the powerful search tools!

### Using the Shell Script (Advanced Users)
```bash
# Make script executable
chmod +x chatgpt_interrogator_v0.8.sh

# Run with your ChatGPT export directory
./chatgpt_interrogator_v0.8.sh /path/to/your/ChatGPT_Export_Directory

# Follow the interactive menu for advanced database operations
```

## 🎯 Usage Examples

### Basic Search Operations
- Search for `"python code"` to find all programming conversations
- Use `"investment strategy"` to locate financial discussions
- Try `"recipe"` or `"cooking"` for culinary conversations
- Search `"data analysis"` to find analytical discussions

### Advanced Filtering Techniques
- **Title-only search**: Find conversations by their titles
- **Content search**: Deep-dive into message content across all conversations
- **Combined search**: Search both titles and content simultaneously
- **Result limiting**: Control how many results you see at once

### Message Analysis
- **User Only**: Review your questions, prompts, and conversation patterns
- **Assistant Only**: Study ChatGPT's responses, code examples, and explanations
- **Both**: Follow complete conversation flows and interaction patterns

## 🔮 Feature Roadmap

### 🎯 **Phase 1: Core Intelligence (Next Release)**
- **🏷️ AI-Powered Tagging System**
  - Automatic content analysis and topic detection
  - Smart tag suggestions based on conversation patterns
  - Custom tag creation with category organization
  - Tag-based search and filtering capabilities

- **📚 Collections & Groups Management**
  - Create named collections for related conversations
  - Hierarchical organization with nested groups
  - Smart collections based on criteria (date, topic, model)
  - Bulk operations for efficient conversation management

- **📤 Advanced Export System**
  - Multiple format support: JSON, Markdown, HTML, CSV, PDF
  - Custom export templates with user-defined formatting
  - Selective export (specific messages, date ranges, filtered results)
  - Batch export for processing multiple conversations

### 🎯 **Phase 2: Advanced Analytics (Future Release)**
- **🤖 AI Analysis & Insights**
  - Automatic conversation summarization with key takeaways
  - Topic clustering and theme identification
  - Conversation pattern recognition and analysis
  - Sentiment analysis of conversation tone and content

- **📊 Enhanced Analytics Dashboard**
  - Usage pattern visualization with timeline charts
  - Topic trend analysis showing evolution over time
  - Model usage statistics (GPT-3.5, GPT-4, etc.)
  - Word clouds and keyword density visualization

- **🔍 Advanced Search Features**
  - Regex support for complex pattern matching
  - Date range filtering with calendar picker interface
  - Message length filters (short/medium/long conversations)
  - Multi-criteria search combining tags, dates, and content
  - Saved search queries for frequently used filters

### 🎯 **Phase 3: Integration & Collaboration (Long-term)**
- **🔄 Real-time Integration**
  - Direct ChatGPT API connectivity for live imports
  - Auto-sync with ChatGPT account for new conversations
  - Incremental updates without re-importing entire datasets
  - Background processing for large dataset management

- **🔗 Collaboration & Sharing**
  - Share insights without exposing personal data
  - Export anonymized analysis results
  - Conversation excerpt sharing for specific discussions
  - Team workspaces for collaborative analysis

- **🎨 Enhanced User Experience**
  - Keyboard shortcuts for power users
  - Conversation comparison with side-by-side viewing
  - Bookmarking system for important conversations
  - Custom theme creation tools
  - Mobile-optimized interface improvements

## 🔧 Technical Architecture

### Frontend Architecture
- **Pure HTML5, CSS3, JavaScript (ES6+)** - No external dependencies
- **CSS Custom Properties** - Theme system with easy customization
- **Modular JavaScript** - Clean separation of concerns for easy extension
- **localStorage Integration** - Persistent user preferences and session data
- **Event-driven Design** - Responsive and interactive user interface

### Backend Integration
- **SQLite Database** - Fast, local storage for conversation data
- **Shell Script Backend** - Advanced database operations and analysis
- **Python Integration** - Data processing and analysis capabilities
- **JSON Processing** - Efficient parsing of ChatGPT export formats

### Browser Compatibility
- ✅ Chrome 80+ (Recommended)
- ✅ Firefox 75+
- ✅ Safari 13+
- ✅ Edge 80+

### Performance Optimizations
- **Fast loading** - Optimized for large conversation datasets (tested with 2000+ conversations)
- **Efficient search** - Indexed database queries for instant results
- **Memory conscious** - Lazy loading and efficient DOM management
- **Responsive design** - Works seamlessly on desktop, tablet, and mobile

## 📊 Tested & Proven

### Scale Testing
- ✅ **2000+ conversations** - Handles large datasets efficiently
- ✅ **200MB+ files** - Processes large export files smoothly
- ✅ **Complex searches** - Instant results across massive conversation histories
- ✅ **Real-world usage** - Tested with actual ChatGPT export data

### Security Testing
- ✅ **XSS Protection** - Safe rendering of user-generated content
- ✅ **Input Validation** - All user inputs sanitized and validated
- ✅ **Privacy Compliance** - No data leaves the user's device
- ✅ **Offline Operation** - Works completely without internet connection

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### 🐛 **Bug Reports**
- Use [GitHub Issues](../../issues) to report bugs
- Include browser version, OS, and steps to reproduce
- Attach screenshots or screen recordings if relevant

### 💡 **Feature Requests**
- Check existing [Issues](../../issues) for similar requests
- Describe the feature, its use case, and expected behavior
- Consider contributing code if you have the skills!

### 🔧 **Development**
```bash
# Fork the repository
git clone https://github.com/Capitalmind/chatgpt_search.git
cd chatgpt_search

# Create feature branch
git checkout -b feature/your-feature-name

# Make changes and test thoroughly
# Follow existing code style and patterns
# Add comments for complex functionality

# Commit with descriptive messages
git commit -m "Add: Detailed description of your feature"

# Push and create pull request
git push origin feature/your-feature-name
```

### 📝 **Documentation**
- Improve README documentation
- Add code comments and examples
- Create usage tutorials or guides
- Update feature descriptions

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **ChatGPT Export Format** - Thanks to OpenAI for providing comprehensive data export functionality
- **Color Palette Design** - Inspired by modern dark theme best practices and professional interfaces
- **Markdown Rendering** - Custom implementation optimized specifically for ChatGPT conversation content
- **Community Feedback** - Thanks to all users providing valuable feedback and feature requests
- **Open Source Community** - Built with inspiration from privacy-focused, local-first applications

## 📞 Support & Community

- **📖 Documentation** - Comprehensive guides in this README and inline code comments
- **🐛 Issues** - Use [GitHub Issues](../../issues) for bug reports and feature requests
- **💬 Discussions** - Use [GitHub Discussions](../../discussions) for questions, ideas, and community chat
- **🔒 Privacy** - For sensitive questions, create a private issue or contact maintainers directly

## 🎯 Project Philosophy

This project embodies the principles of **privacy-first software development**:

- **Your data is yours** - Never uploaded, never shared, never tracked
- **Transparency first** - Open source, auditable, and community-driven
- **Local processing** - All analysis happens on your device
- **User empowerment** - Powerful tools without sacrificing privacy
- **Future-proof design** - Extensible architecture for ongoing development

---

**⚡ Transform your ChatGPT history into searchable, organized insights today!**

*Discover patterns, find forgotten conversations, and gain new perspectives on your AI interactions - all while keeping your data completely private and secure.*

---

### 🔗 Quick Links
- [Download Latest Release](../../releases)
- [View Source Code](../../)
- [Report Issues](../../issues)
- [Feature Requests](../../issues/new)
- [Documentation](../../wiki)

**Star ⭐ this repository if you find it useful!**