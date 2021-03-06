require 'asciidoctor/backends/_stylesheets'

module Asciidoctor
module HTML5

class DocumentTemplate < BaseTemplate
  # FIXME make this outline generic
  def self.outline(node, to_depth = 2, sectnumlevels = nil)
    sectnumlevels = (node.document.attr 'sectnumlevels', 3).to_i if sectnumlevels.nil?
    toc_level_buffer = []
    sections = node.sections
    unless sections.empty?
      # FIXME the level for special sections should be set correctly in the model
      # sec_level will only be 0 if we have a book doctype with parts
      sec_level = sections.first.level
      if sec_level == 0 && sections.first.special
        sec_level = 1
      end
      toc_level_buffer << %(<ul class="sectlevel#{sec_level}">)
      sections.each do |section|
        section_num = (section.numbered && section.caption.nil? && section.level <= sectnumlevels) ? %(#{section.sectnum} ) : nil
        toc_level_buffer << %(<li><a href=\"##{section.id}\">#{section_num}#{section.captioned_title}</a></li>)
        if section.level < to_depth && (child_toc_level = outline(section, to_depth, sectnumlevels)) != ''
          toc_level_buffer << '<li>'
          toc_level_buffer << child_toc_level
          toc_level_buffer << '</li>'
        end
      end
      toc_level_buffer << '</ul>'
    end
    toc_level_buffer * EOL
  end

  def result node
    result_buffer = []
    short_tag_slash_local = node.short_tag_slash
    br = %(<br#{short_tag_slash_local}>)
    linkcss = node.safe >= SafeMode::SECURE || (node.attr? 'linkcss')
    result_buffer << '<!DOCTYPE html>'
    result_buffer << ((node.attr? 'nolang') ? '<html>' : %(<html lang="#{node.attr 'lang', 'en'}">))
    result_buffer << %(<head>
<meta http-equiv="Content-Type" content="text/html; charset=#{node.attr 'encoding'}"#{short_tag_slash_local}>
<meta name="generator" content="Asciidoctor #{node.attr 'asciidoctor-version'}"#{short_tag_slash_local}>
<meta name="viewport" content="width=device-width, initial-scale=1.0"#{short_tag_slash_local}>)

    ['description', 'keywords', 'author', 'copyright'].each do |key|
      result_buffer << %(<meta name="#{key}" content="#{node.attr key}"#{short_tag_slash_local}>) if node.attr? key
    end

    result_buffer << %(<title>#{node.doctitle(:sanitize => true) || node.attr('untitled-label')}</title>) 
    if DEFAULT_STYLESHEET_KEYS.include?(node.attr 'stylesheet')
      if linkcss
        result_buffer << %(<link rel="stylesheet" href="#{node.normalize_web_path DEFAULT_STYLESHEET_NAME, (node.attr 'stylesdir', '')}"#{short_tag_slash_local}>)
      else
        result_buffer << %(<style>
#{HTML5.default_asciidoctor_stylesheet}
</style>)
      end
    elsif node.attr? 'stylesheet'
      if linkcss
        result_buffer << %(<link rel="stylesheet" href="#{node.normalize_web_path((node.attr 'stylesheet'), (node.attr 'stylesdir', ''))}"#{short_tag_slash_local}>)
      else
        result_buffer << %(<style>
#{node.read_asset node.normalize_system_path((node.attr 'stylesheet'), (node.attr 'stylesdir', '')), true}
</style>)
      end
    end

    if node.attr? 'icons', 'font'
      if !(node.attr 'iconfont-remote', '').nil?
        result_buffer << %(<link rel="stylesheet" href="#{node.attr 'iconfont-cdn', 'http://cdnjs.cloudflare.com/ajax/libs/font-awesome/3.2.1/css/font-awesome.min.css'}"#{short_tag_slash_local}>)
      else
        iconfont_stylesheet = %(#{node.attr 'iconfont-name', 'font-awesome'}.css)
        result_buffer << %(<link rel="stylesheet" href="#{node.normalize_web_path iconfont_stylesheet, (node.attr 'stylesdir', '')}"#{short_tag_slash_local}>)
      end
    end

    case node.attr 'source-highlighter'
    when 'coderay'
      if (node.attr 'coderay-css', 'class') == 'class'
        if linkcss
          result_buffer << %(<link rel="stylesheet" href="#{node.normalize_web_path 'asciidoctor-coderay.css', (node.attr 'stylesdir', '')}"#{short_tag_slash_local}>)
        else
          result_buffer << %(<style>
#{HTML5.default_coderay_stylesheet}
</style>)
        end
      end
    when 'pygments'
      if (node.attr 'pygments-css', 'class') == 'class'
        if linkcss
          result_buffer << %(<link rel="stylesheet" href="#{node.normalize_web_path 'asciidoctor-pygments.css', (node.attr 'stylesdir', '')}"#{short_tag_slash_local}>)
        else
          result_buffer << %(<style>
#{HTML5.pygments_stylesheet(node.attr 'pygments-style')}
</style>)
        end
      end
    when 'highlightjs', 'highlight.js'
      result_buffer << %(<link rel="stylesheet" href="#{node.attr 'highlightjsdir', 'http://cdnjs.cloudflare.com/ajax/libs/highlight.js/7.4'}/styles/#{node.attr 'highlightjs-theme', 'googlecode'}.min.css"#{short_tag_slash_local}>
<script src="#{node.attr 'highlightjsdir', 'http://cdnjs.cloudflare.com/ajax/libs/highlight.js/7.4'}/highlight.min.js"></script>
<script src="#{node.attr 'highlightjsdir', 'http://cdnjs.cloudflare.com/ajax/libs/highlight.js/7.4'}/lang/common.min.js"></script>
<script>hljs.initHighlightingOnLoad()</script>)
    when 'prettify'
      result_buffer << %(<link rel="stylesheet" href="#{node.attr 'prettifydir', 'http://cdnjs.cloudflare.com/ajax/libs/prettify/r298'}/#{node.attr 'prettify-theme', 'prettify'}.min.css"#{short_tag_slash_local}>
<script src="#{node.attr 'prettifydir', 'http://cdnjs.cloudflare.com/ajax/libs/prettify/r298'}/prettify.min.js"></script>
<script>document.addEventListener('DOMContentLoaded', prettyPrint)</script>)
    end

    if node.attr? 'math'
      result_buffer << %(<script type="text/x-mathjax-config">
MathJax.Hub.Config({
  tex2jax: {
    inlineMath: [#{INLINE_MATH_DELIMITERS[:latexmath]}],
    displayMath: [#{BLOCK_MATH_DELIMITERS[:latexmath]}],
    ignoreClass: "nomath|nolatexmath"
  },
  asciimath2jax: {
    delimiters: [#{BLOCK_MATH_DELIMITERS[:asciimath]}],
    ignoreClass: "nomath|noasciimath"
  }
});
</script>
<script type="text/javascript" src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-MML-AM_HTMLorMML"></script>
<script>document.addEventListener('DOMContentLoaded', MathJax.Hub.TypeSet)</script>)
    end

    unless (docinfo_content = node.docinfo).empty?
      result_buffer << docinfo_content
    end

    result_buffer << '</head>'
    body_attrs = []
    if node.id
      body_attrs << %(id="#{node.id}")
    end
    if (node.attr? 'toc-class') && (node.attr? 'toc') && (node.attr? 'toc-placement', 'auto')
      body_attrs << %(class="#{node.doctype} #{node.attr 'toc-class'} toc-#{node.attr 'toc-position', 'left'}")
    else
      body_attrs << %(class="#{node.doctype}")
    end
    if node.attr? 'max-width'
      body_attrs << %(style="max-width: #{node.attr 'max-width'};")
    end
    result_buffer << %(<body #{body_attrs * ' '}>)

    unless node.noheader
      result_buffer << '<div id="header">'
      if node.doctype == 'manpage'
        result_buffer << %(<h1>#{node.doctitle} Manual Page</h1>)
        if (node.attr? 'toc') && (node.attr? 'toc-placement', 'auto')
          result_buffer << %(<div id="toc" class="#{node.attr 'toc-class', 'toc'}">
<div id="toctitle">#{node.attr 'toc-title'}</div>
#{DocumentTemplate.outline node, (node.attr 'toclevels', 2).to_i}
</div>)
        end
        result_buffer << %(<h2>#{node.attr 'manname-title'}</h2>
<div class="sectionbody">
<p>#{node.attr 'manname'} - #{node.attr 'manpurpose'}</p>
</div>)
      else
        if node.has_header?
          result_buffer << %(<h1>#{node.header.title}</h1>) unless node.notitle
          if node.attr? 'author'
            result_buffer << %(<span id="author" class="author">#{node.attr 'author'}</span>#{br})
            if node.attr? 'email'
              result_buffer << %(<span id="email" class="email">#{node.sub_macros(node.attr 'email')}</span>#{br})
            end
            if (authorcount = (node.attr 'authorcount').to_i) > 1
              (2..authorcount).each do |idx|
                result_buffer << %(<span id="author#{idx}" class="author">#{node.attr "author_#{idx}"}</span>#{br})
                if node.attr? %(email_#{idx})
                  result_buffer << %(<span id="email#{idx}" class="email">#{node.sub_macros(node.attr "email_#{idx}")}</span>#{br})
                end
              end
            end
          end
          if node.attr? 'revnumber'
            result_buffer << %(<span id="revnumber">#{((node.attr 'version-label') || '').downcase} #{node.attr 'revnumber'}#{(node.attr? 'revdate') ? ',' : ''}</span>)
          end
          if node.attr? 'revdate'
            result_buffer << %(<span id="revdate">#{node.attr 'revdate'}</span>)
          end
          if node.attr? 'revremark'
            result_buffer << %(#{br}<span id="revremark">#{node.attr 'revremark'}</span>)
          end
        end

        if (node.attr? 'toc') && (node.attr? 'toc-placement', 'auto')
          result_buffer << %(<div id="toc" class="#{node.attr 'toc-class', 'toc'}">
<div id="toctitle">#{node.attr 'toc-title'}</div>
#{DocumentTemplate.outline node, (node.attr 'toclevels', 2).to_i}
</div>)
        end
      end
      result_buffer << '</div>'
    end

    result_buffer << %(<div id="content">
#{node.content}
</div>)

    if node.footnotes? && !(node.attr? 'nofootnotes')
      result_buffer << %(<div id="footnotes">
<hr#{short_tag_slash_local}>)
      node.footnotes.each do |footnote|
        result_buffer << %(<div class="footnote" id="_footnote_#{footnote.index}">
<a href="#_footnoteref_#{footnote.index}">#{footnote.index}</a>. #{footnote.text}
</div>)
      end
      result_buffer << '</div>'
    end
    unless node.nofooter
      result_buffer << '<div id="footer">'
      result_buffer << '<div id="footer-text">'
      if node.attr? 'revnumber'
        result_buffer << %(#{node.attr 'version-label'} #{node.attr 'revnumber'}#{br})
      end
      if node.attr? 'last-update-label'
        result_buffer << %(#{node.attr 'last-update-label'} #{node.attr 'docdatetime'})
      end
      result_buffer << '</div>'
      unless (docinfo_content = node.docinfo :footer).empty?
        result_buffer << docinfo_content
      end
      result_buffer << '</div>'
    end

    result_buffer << '</body>'
    result_buffer << '</html>'
    result_buffer * EOL
  end

  def template
    # FIXME remove need for this special case!!
    :invoke_result_document
  end
end

class EmbeddedTemplate < BaseTemplate
  def result(node)
    result_buffer = []
    if !node.notitle && node.has_header?
      id_attr = node.id ? %( id="#{node.id}") : nil
      result_buffer << %(<h1#{id_attr}>#{node.header.title}</h1>)
    end

    result_buffer << node.content

    if node.footnotes? && !(node.attr? 'nofootnotes')
      result_buffer << '<div id="footnotes">'
      result_buffer << %(<hr#{node.short_tag_slash}>)
      node.footnotes.each do |footnote|
        result_buffer << %(<div class="footnote" id="_footnote_#{footnote.index}">
<a href="#_footnoteref_#{footnote.index}">#{footnote.index}</a> #{footnote.text}
</div>)
      end

      result_buffer << '</div>'
    end

    result_buffer * EOL
  end

  def template
    :invoke_result_document
  end
end

class BlockTocTemplate < BaseTemplate
  def result(node)
    doc = node.document

    return '' unless (doc.attr? 'toc')

    if node.id
      id_attr = %( id="#{node.id}")
      title_id_attr = ''
    elsif doc.embedded? || !(doc.attr? 'toc-placement')
      id_attr = ' id="toc"'
      title_id_attr = ' id="toctitle"'
    else
      id_attr = ''
      title_id_attr = ''
    end
    title = node.title? ? node.title : (doc.attr 'toc-title')
    levels = (node.attr? 'levels') ? (node.attr 'levels').to_i : (doc.attr 'toclevels', 2).to_i
    role = node.role? ? node.role : (doc.attr 'toc-class', 'toc')

    %(<div#{id_attr} class="#{role}">
<div#{title_id_attr} class="title">#{title}</div>
#{DocumentTemplate.outline(doc, levels)}
</div>\n)
  end

  def template
    :invoke_result
  end
end

class BlockPreambleTemplate < BaseTemplate
  def toc(node)
    if (node.attr? 'toc') && (node.attr? 'toc-placement', 'preamble')
      %(\n<div id="toc" class="#{node.attr 'toc-class', 'toc'}">
<div id="toctitle">#{node.attr 'toc-title'}</div>
#{DocumentTemplate.outline(node.document, (node.attr 'toclevels', 2).to_i)}
</div>)
    else
      ''
    end
  end

  def result(node)
    %(<div id="preamble">
<div class="sectionbody">
#{node.content}
</div>#{toc node}
</div>)
  end

  def template
    :invoke_result
  end
end

class SectionTemplate < BaseTemplate
  def result(sec)
    slevel = sec.level
    # QUESTION should this check be done in section?
    if slevel == 0 && sec.special
      slevel = 1
    end
    htag = "h#{slevel + 1}"
    id = anchor = link_start = link_end = nil
    if sec.id
      id = %( id="#{sec.id}")
      if sec.document.attr? 'sectanchors'
        #if sec.document.attr? 'icons', 'font'
        #  anchor = %(<a class="anchor" href="##{sec.id}"><i class="icon-anchor"></i></a>)
        #else
          anchor = %(<a class="anchor" href="##{sec.id}"></a>)
        #end
      elsif sec.document.attr? 'sectlinks'
        link_start = %(<a class="link" href="##{sec.id}">)
        link_end = '</a>'
      end
    end

    if slevel == 0
      %(<h1#{id} class="sect0">#{anchor}#{link_start}#{sec.title}#{link_end}</h1>
#{sec.content})
    else
      role = sec.role? ? " #{sec.role}" : nil
      sectnum = nil
      if sec.numbered && sec.caption.nil? && slevel <= (sec.document.attr 'sectnumlevels', 3).to_i
        sectnum = "#{sec.sectnum} "
      end

      if slevel == 1
        content = %(<div class="sectionbody">
#{sec.content}
</div>)
      else
        content = sec.content
      end
      %(<div class="sect#{slevel}#{role}">
<#{htag}#{id}>#{anchor}#{link_start}#{sectnum}#{sec.captioned_title}#{link_end}</#{htag}>
#{content}
</div>)
    end
  end

  def template
    :invoke_result
  end
end

class BlockFloatingTitleTemplate < BaseTemplate
  def result(node)
    tag_name = "h#{node.level + 1}"
    id_attribute = node.id ? %( id="#{node.id}") : nil
    classes = [node.style, node.role].compact
    %(<#{tag_name}#{id_attribute} class="#{classes * ' '}">#{node.title}</#{tag_name}>)
  end

  def template
    :invoke_result
  end
end

class BlockDlistTemplate < BaseTemplate
  def result(node)
    result_buffer = []
    id_attribute = node.id ? %( id="#{node.id}") : nil

    case node.style
    when 'qanda'
      classes = ['qlist', 'qanda', node.role].compact
    when 'horizontal'
      classes = ['hdlist', node.role].compact
    else
      classes = ['dlist', node.style, node.role].compact
    end

    class_attribute = %( class="#{classes * ' '}")

    result_buffer << %(<div#{id_attribute}#{class_attribute}>)
    result_buffer << %(<div class="title">#{node.title}</div>) if node.title?
    case node.style
    when 'qanda'
      result_buffer << '<ol>'
      node.items.each do |terms, dd|
        result_buffer << '<li>'
        [*terms].each do |dt|
          result_buffer << %(<p><em>#{dt.text}</em></p>)
        end
        unless dd.nil?
          result_buffer << %(<p>#{dd.text}</p>) if dd.text?
          result_buffer << dd.content if dd.blocks?
        end
        result_buffer << '</li>'
      end
      result_buffer << '</ol>'
    when 'horizontal'
      short_tag_slash_local = node.short_tag_slash
      result_buffer << '<table>'
      if (node.attr? 'labelwidth') || (node.attr? 'itemwidth')
        result_buffer << '<colgroup>'
        col_style_attribute = (node.attr? 'labelwidth') ? %( style="width: #{(node.attr 'labelwidth').chomp '%'}%;") : nil
        result_buffer << %(<col#{col_style_attribute}#{short_tag_slash_local}>)
        col_style_attribute = (node.attr? 'itemwidth') ? %( style="width: #{(node.attr 'itemwidth').chomp '%'}%;") : nil
        result_buffer << %(<col#{col_style_attribute}#{short_tag_slash_local}>)
        result_buffer << '</colgroup>'
      end
      node.items.each do |terms, dd|
        result_buffer << '<tr>'
        result_buffer << %(<td class="hdlist1#{(node.option? 'strong') ? ' strong' : nil}">)
        terms_array = [*terms]
        last_term = terms_array.last
        terms_array.each do |dt|
          result_buffer << dt.text
          result_buffer << %(<br#{short_tag_slash_local}>) if dt != last_term
        end
        result_buffer << '</td>'
        result_buffer << '<td class="hdlist2">'
        unless dd.nil?
          result_buffer << %(<p>#{dd.text}</p>) if dd.text?
          result_buffer << dd.content if dd.blocks?
        end
        result_buffer << '</td>'
        result_buffer << '</tr>'
      end
      result_buffer << '</table>'
    else
      result_buffer << '<dl>'
      dt_style_attribute = node.style.nil? ? ' class="hdlist1"' : nil
      node.items.each do |terms, dd|
        [*terms].each do |dt|
          result_buffer << %(<dt#{dt_style_attribute}>#{dt.text}</dt>)
        end
        unless dd.nil?
          result_buffer << '<dd>'
          result_buffer << %(<p>#{dd.text}</p>) if dd.text?
          result_buffer << dd.content if dd.blocks?
          result_buffer << '</dd>'
        end
      end
      result_buffer << '</dl>'
    end

    result_buffer << '</div>'
    result_buffer * EOL
  end

  def template
    :invoke_result
  end
end

class BlockListingTemplate < BaseTemplate
  def result(node)
    nowrap = (!node.document.attr? 'prewrap') || (node.option? 'nowrap')
    if node.style == 'source'
      language = node.attr 'language'
      language_classes = language ? %(#{language} language-#{language}) : nil
      case node.attr 'source-highlighter'
      when 'coderay'
        pre_class = nowrap ? ' class="CodeRay nowrap"' : ' class="CodeRay"'
        code_class = language ? %( class="#{language_classes}") : nil
      when 'pygments'
        pre_class = nowrap ? ' class="pygments highlight nowrap"' : ' class="pygments highlight"'
        code_class = language ? %( class="#{language_classes}") : nil
      when 'highlightjs', 'highlight.js'
        pre_class = nowrap ? ' class="highlight nowrap"' : ' class="highlight"'
        code_class = language ? %( class="#{language_classes}") : nil
      when 'prettify'
        pre_class = %( class="prettyprint#{nowrap ? ' nowrap' : nil}#{(node.attr? 'linenums') ? ' linenums' : nil})
        pre_class = language ? %(#{pre_class} #{language_classes}") : %(#{pre_class}")
        code_class = nil
      when 'html-pipeline'
        pre_class = language ? %( lang="#{language}") : nil
        code_class = nil
      else
        pre_class = nowrap ? ' class="highlight nowrap"' : ' class="highlight"'
        code_class = language ? %( class="#{language_classes}") : nil
      end
      pre = %(<pre#{pre_class}><code#{code_class}>#{preserve_endlines(node.content, node)}</code></pre>)
    else
      pre = %(<pre#{nowrap ? ' class="nowrap"' : nil}>#{preserve_endlines(node.content, node)}</pre>)
    end

    %(<div#{node.id && " id=\"#{node.id}\""} class="listingblock#{node.role && " #{node.role}"}">#{node.title? ? "
<div class=\"title\">#{node.captioned_title}</div>" : nil}
<div class="content">
#{pre}
</div>
</div>)
  end

  def template
    :invoke_result
  end
end

class BlockLiteralTemplate < BaseTemplate
  def result(node)
    nowrap = (!node.document.attr? 'prewrap') || (node.option? 'nowrap')
    %(<div#{node.id && " id=\"#{node.id}\""} class="literalblock#{node.role && " #{node.role}"}">#{node.title? ? "
<div class=\"title\">#{node.title}</div>" : nil}
<div class="content">
<pre#{nowrap ? ' class="nowrap"' : nil}>#{preserve_endlines(node.content, node)}</pre>
</div>
</div>)
  end

  def template
    :invoke_result
  end
end

class BlockAdmonitionTemplate < BaseTemplate
  def result(node)
    id = node.id
    name = node.attr 'name'
    role = node.role
    title = node.title? ? node.title : nil
    if node.document.attr? 'icons'
      if node.document.attr? 'icons', 'font'
        caption = %(<i class="icon-#{name}" title="#{node.caption}"></i>)
      else
        caption = %(<img src="#{node.icon_uri(name)}" alt="#{node.caption}"#{node.short_tag_slash}>)
      end
    else
      caption = %(<div class="title">#{node.caption}</div>)
    end
    %(<div#{id && " id=\"#{id}\""} class="admonitionblock #{name}#{role && " #{role}"}">
<table>
<tr>
<td class="icon">
#{caption}
</td>
<td class="content">#{title ? "
<div class=\"title\">#{title}</div>" : nil}
#{node.content}
</td>
</tr>
</table>
</div>)
  end

  def template
    :invoke_result
  end
end

class BlockParagraphTemplate < BaseTemplate
  def result(node)
    id_attr = node.id ? %( id="#{node.id}") : nil
    title_element = node.title? ? %(<div class="title">#{node.title}</div>\n) : nil
    role_val = (role = node.role) ? %( #{role}) : nil

    %(<div#{id_attr} class="paragraph#{role_val}">
#{title_element}<p>#{node.content}</p>
</div>)
  end

  def template
    :invoke_result
  end
end

class BlockSidebarTemplate < BaseTemplate
  def result(node)
    id_attribute = node.id ? %( id="#{node.id}") : nil
    title_element = node.title? ? %(<div class="title">#{node.title}</div>\n) : nil

    %(<div#{id_attribute} class="#{!node.role? ? 'sidebarblock' : ['sidebarblock', node.role] * ' '}">
<div class="content">
#{title_element}#{node.content}
</div>
</div>)
  end

  def template
    :invoke_result
  end
end

class BlockExampleTemplate < BaseTemplate
  def result(node)
    id_attribute = node.id ? %( id="#{node.id}") : nil
    title_element = node.title? ? %(<div class="title">#{node.captioned_title}</div>\n) : nil

    %(<div#{id_attribute} class="#{!node.role? ? 'exampleblock' : ['exampleblock', node.role] * ' '}">
#{title_element}<div class="content">
#{node.content}
</div>
</div>)
  end

  def template
    :invoke_result
  end
end

class BlockOpenTemplate < BaseTemplate
  def result(node)
    open_block(node, node.id, node.style, node.role, node.title? ? node.title : nil, node.content)
  end

  def open_block(node, id, style, role, title, content)
    if style == 'abstract'
      if node.parent == node.document && node.document.doctype == 'book'
        warn 'asciidoctor: WARNING: abstract block cannot be used in a document without a title when doctype is book. Excluding block content.'
        ''
      else
        %(<div#{id && " id=\"#{id}\""} class="quoteblock abstract#{role && " #{role}"}">#{title &&
"<div class=\"title\">#{title}</div>"}
<blockquote>
#{content}
</blockquote>
</div>)
      end
    elsif style == 'partintro' && (node.level != 0 || node.parent.context != :section || node.document.doctype != 'book')
      warn 'asciidoctor: ERROR: partintro block can only be used when doctype is book and it\'s a child of a book part. Excluding block content.'
      ''
    else
      %(<div#{id && " id=\"#{id}\""} class="openblock#{style != 'open' ? " #{style}" : ''}#{role && " #{role}"}">#{title &&
"<div class=\"title\">#{title}</div>"}
<div class="content">
#{content}
</div>
</div>)
    end
  end

  def template
    :invoke_result
  end
end

class BlockPassTemplate < BaseTemplate
  def template
    :content
  end
end

class BlockMathTemplate < BaseTemplate
  def result node
    id_attribute = node.id ? %( id="#{node.id}") : nil
    title_element = node.title? ? %(<div class="title">#{node.title}</div>\n) : nil
    open, close = BLOCK_MATH_DELIMITERS[node.style.to_sym]
    equation = node.content.strip
    if (node.subs.nil? || node.subs.empty?) && !(node.attr? 'subs')
      equation = node.sub_specialcharacters(equation)
    end

    unless (equation.start_with? open) && (equation.end_with? close)
      equation = %(#{open}#{equation}#{close})
    end
    
    %(<div#{id_attribute} class="#{node.role? ? ['mathblock', node.role] * ' ' : 'mathblock'}">
#{title_element}<div class="content">
#{equation}
</div>
</div>)
  end

  def template
    :invoke_result
  end
end

class BlockQuoteTemplate < BaseTemplate
  def result(node)
    id_attribute = node.id ? %( id="#{node.id}") : nil
    classes = ['quoteblock', node.role].compact
    class_attribute = %( class="#{classes * ' '}")
    title_element = node.title? ? %(\n<div class="title">#{node.title}</div>) : nil
    attribution = (node.attr? 'attribution') ? (node.attr 'attribution') : nil
    citetitle = (node.attr? 'citetitle') ? (node.attr 'citetitle') : nil
    if attribution || citetitle
      cite_element = citetitle ? %(<cite>#{citetitle}</cite>) : nil
      attribution_text = attribution ? %(#{citetitle ? "<br#{node.short_tag_slash}>\n" : nil}&#8212; #{attribution}) : nil
      attribution_element = %(\n<div class="attribution">\n#{cite_element}#{attribution_text}\n</div>)
    else
      attribution_element = nil
    end

    %(<div#{id_attribute}#{class_attribute}>#{title_element}
<blockquote>
#{node.content}
</blockquote>#{attribution_element}
</div>)
  end

  def template
    :invoke_result
  end
end

class BlockVerseTemplate < BaseTemplate
  def result(node)
    id_attribute = node.id ? %( id="#{node.id}") : nil
    classes = ['verseblock', node.role].compact
    class_attribute = %( class="#{classes * ' '}")
    title_element = node.title? ? %(\n<div class="title">#{node.title}</div>) : nil
    attribution = (node.attr? 'attribution') ? (node.attr 'attribution') : nil
    citetitle = (node.attr? 'citetitle') ? (node.attr 'citetitle') : nil
    if attribution || citetitle
      cite_element = citetitle ? %(<cite>#{citetitle}</cite>) : nil
      attribution_text = attribution ? %(#{citetitle ? "<br#{node.short_tag_slash}>\n" : nil}&#8212; #{attribution}) : nil
      attribution_element = %(\n<div class="attribution">\n#{cite_element}#{attribution_text}\n</div>)
    else
      attribution_element = nil
    end

    %(<div#{id_attribute}#{class_attribute}>#{title_element}
<pre class="content">#{preserve_endlines node.content, node}</pre>#{attribution_element}
</div>)
  end

  def template
    :invoke_result
  end
end

class BlockUlistTemplate < BaseTemplate
  def result(node)
    result_buffer = []
    id_attribute = node.id ? %( id="#{node.id}") : nil
    div_classes = ['ulist', node.style, node.role].compact
    marker_checked = nil
    marker_unchecked = nil
    if (checklist = (node.option? 'checklist'))
      div_classes.insert(1, 'checklist')
      ul_class_attribute = ' class="checklist"'
      if node.option? 'interactive'
        if node.document.attr? 'htmlsyntax', 'xml'
          marker_checked = '<input type="checkbox" data-item-complete="1" checked="checked"/> '
          marker_unchecked = '<input type="checkbox" data-item-complete="0"/> '
        else
          marker_checked = '<input type="checkbox" data-item-complete="1" checked> '
          marker_unchecked = '<input type="checkbox" data-item-complete="0"> '
        end
      else
        if node.document.attr? 'icons', 'font'
          marker_checked = '<i class="icon-check"></i> '
          marker_unchecked = '<i class="icon-check-empty"></i> '
        else
          # could use &#9745 (checked ballot) and &#9744 (ballot) w/o font instead
          if node.document.attr? 'htmlsyntax', 'xml'
            marker_checked = '<input type="checkbox" data-item-complete="1" checked="checked" disabled="disabled"/> '
            marker_unchecked = '<input type="checkbox" data-item-complete="0" disabled="disabled"/> '
          else
            marker_checked = '<input type="checkbox" data-item-complete="1" checked disabled> '
            marker_unchecked = '<input type="checkbox" data-item-complete="0" disabled> '
          end
        end
      end
    elsif !node.style.nil?
      ul_class_attribute = %( class="#{node.style}")
    else
      ul_class_attribute = nil
    end
    div_class_attribute = %( class="#{div_classes * ' '}")
    result_buffer << %(<div#{id_attribute}#{div_class_attribute}>)
    result_buffer << %(<div class="title">#{node.title}</div>) if node.title?
    result_buffer << %(<ul#{ul_class_attribute}>)

    node.items.each do |item|
      if checklist && (item.attr? 'checkbox')
        marker = (item.attr? 'checked') ? marker_checked : marker_unchecked
      else
        marker = nil
      end
      result_buffer << '<li>'
      result_buffer << %(<p>#{marker}#{item.text}</p>)
      result_buffer << item.content if item.blocks?
      result_buffer << '</li>'
    end

    result_buffer << '</ul>'
    result_buffer << '</div>'

    result_buffer * EOL
  end

  def template
    :invoke_result
  end
end

class BlockOlistTemplate < BaseTemplate
  def result(node)
    result_buffer = []
    id_attribute = node.id ? %( id="#{node.id}") : nil
    classes = ['olist', node.style, node.role].compact
    class_attribute = %( class="#{classes * ' '}")

    result_buffer << %(<div#{id_attribute}#{class_attribute}>)
    result_buffer << %(<div class="title">#{node.title}</div>) if node.title?

    type_attribute = (keyword = node.list_marker_keyword) ? %( type="#{keyword}") : nil
    start_attribute = (node.attr? 'start') ? %( start="#{node.attr 'start'}") : nil
    result_buffer << %(<ol class="#{node.style}"#{type_attribute}#{start_attribute}>)

    node.items.each do |item|
      result_buffer << '<li>'
      result_buffer << %(<p>#{item.text}</p>)
      result_buffer << item.content if item.blocks?
      result_buffer << '</li>'
    end

    result_buffer << '</ol>'
    result_buffer << '</div>'

    result_buffer * EOL
  end

  def template
    :invoke_result
  end
end

class BlockColistTemplate < BaseTemplate
  def result(node)
    result_buffer = []
    id_attribute = node.id ? %( id="#{node.id}") : nil
    classes = ['colist', node.style, node.role].compact
    class_attribute = %( class="#{classes * ' '}")

    result_buffer << %(<div#{id_attribute}#{class_attribute}>)
    result_buffer << %(<div class="title">#{node.title}</div>) if node.title?

    if node.document.attr? 'icons'
      result_buffer << '<table>'

      font_icons = node.document.attr? 'icons', 'font'
      node.items.each_with_index do |item, i|
        num = i + 1
        num_element = font_icons ?
            %(<i class="conum" data-value="#{num}"></i><b>#{num}</b>) :
            %(<img src="#{node.icon_uri "callouts/#{num}"}" alt="#{num}"#{node.short_tag_slash}>)
        result_buffer << %(<tr>
<td>#{num_element}</td>
<td>#{item.text}</td>
</tr>)
      end

      result_buffer << '</table>'
    else
      result_buffer << '<ol>'
      node.items.each do |item|
        result_buffer << %(<li>
<p>#{item.text}</p>
</li>)
      end
      result_buffer << '</ol>'
    end

    result_buffer << '</div>'
    result_buffer * EOL
  end

  def template
    :invoke_result
  end
end

class BlockTableTemplate < BaseTemplate
  def result(node)
    result_buffer = [] 
    id_attribute = node.id ? %( id="#{node.id}") : nil
    classes = ['tableblock', %(frame-#{node.attr 'frame', 'all'}), %(grid-#{node.attr 'grid', 'all'})]
    if (role_class = node.role)
      classes << role_class
    end
    class_attribute = %( class="#{classes * ' '}")
    styles = [(node.option? 'autowidth') ? nil : %(width: #{node.attr 'tablepcwidth'}%;), (node.attr? 'float') ? %(float: #{node.attr 'float'};) : nil].compact
    if styles.size > 0
      style_attribute = %( style="#{styles * ' '}")
    else
      style_attribute = nil
    end

    result_buffer << %(<table#{id_attribute}#{class_attribute}#{style_attribute}>)
    if node.title?
      result_buffer << %(<caption class="title">#{node.captioned_title}</caption>)
    end
    if (node.attr 'rowcount') > 0
      result_buffer << '<colgroup>'
      if node.option? 'autowidth'
        tag = %(<col#{node.short_tag_slash}>)
        node.columns.size.times do
          result_buffer << tag
        end
      else
        short_tag_slash_local = node.short_tag_slash
        node.columns.each do |col|
          result_buffer << %(<col style="width: #{col.attr 'colpcwidth'}%;"#{short_tag_slash_local}>)
        end
      end
      result_buffer << '</colgroup>'
      [:head, :foot, :body].select {|tsec| !node.rows[tsec].empty? }.each do |tsec|
        result_buffer << %(<t#{tsec}>)
        node.rows[tsec].each do |row|
          result_buffer << '<tr>'
          row.each do |cell|
            if tsec == :head
              cell_content = cell.text
            else
              case cell.style
              when :asciidoc
                cell_content = %(<div>#{cell.content}</div>)
              when :verse
                cell_content = %(<div class="verse">#{preserve_endlines cell.text, node}</div>)
              when :literal
                cell_content = %(<div class="literal"><pre>#{preserve_endlines cell.text, node}</pre></div>)
              else
                cell_content = ''
                cell.content.each do |text|
                  cell_content = %(#{cell_content}<p class="tableblock">#{text}</p>)
                end
              end
            end

            cell_tag_name = (tsec == :head || cell.style == :header ? 'th' : 'td')
            cell_class_attribute = %( class="tableblock halign-#{cell.attr 'halign'} valign-#{cell.attr 'valign'}")
            cell_colspan_attribute = cell.colspan ? %( colspan="#{cell.colspan}") : nil
            cell_rowspan_attribute = cell.rowspan ? %( rowspan="#{cell.rowspan}") : nil
            cell_style_attribute = (node.document.attr? 'cellbgcolor') ? %( style="background-color: #{node.document.attr 'cellbgcolor'};") : nil
            result_buffer << %(<#{cell_tag_name}#{cell_class_attribute}#{cell_colspan_attribute}#{cell_rowspan_attribute}#{cell_style_attribute}>#{cell_content}</#{cell_tag_name}>)
          end
          result_buffer << '</tr>'
        end
        result_buffer << %(</t#{tsec}>)
      end
    end
    result_buffer << %(</table>)
    result_buffer * EOL
  end

  def template
    :invoke_result
  end
end

class BlockImageTemplate < BaseTemplate
  def image(target, alt, title, link, node)
    align = (node.attr? 'align') ? (node.attr 'align') : nil
    float = (node.attr? 'float') ? (node.attr 'float') : nil 
    if align || float
      styles = [align ? %(text-align: #{align}) : nil, float ? %(float: #{float}) : nil].compact
      style_attribute = %( style="#{styles * ';'}")
    else
      style_attribute = nil
    end

    width_attribute = (node.attr? 'width') ? %( width="#{node.attr 'width'}") : nil
    height_attribute = (node.attr? 'height') ? %( height="#{node.attr 'height'}") : nil

    img_element = %(<img src="#{node.image_uri target}" alt="#{alt}"#{width_attribute}#{height_attribute}#{node.short_tag_slash}>)
    if link
      img_element = %(<a class="image" href="#{link}">#{img_element}</a>)
    end
    id_attribute = node.id ? %( id="#{node.id}") : nil
    classes = ['imageblock', node.style, node.role].compact
    class_attribute = %( class="#{classes * ' '}")
    title_element = title ? %(\n<div class="title">#{title}</div>) : nil

    %(<div#{id_attribute}#{class_attribute}#{style_attribute}>
<div class="content">
#{img_element}
</div>#{title_element}
</div>)
  end

  def result(node)
    image(node.attr('target'), node.attr('alt'), node.title? ? node.captioned_title : nil, node.attr('link'), node)
  end

  def template
    :invoke_result
  end
end

class BlockAudioTemplate < BaseTemplate
  def result(node)
    xml = node.document.attr? 'htmlsyntax', 'xml'
    id_attribute = node.id ? %( id="#{node.id}") : nil
    classes = ['audioblock', node.style, node.role].compact
    class_attribute = %( class="#{classes * ' '}")
    title_element = node.title? ? %(\n<div class="title">#{node.captioned_title}</div>) : nil
    %(<div#{id_attribute}#{class_attribute}>#{title_element}
<div class="content">
<audio src="#{node.media_uri(node.attr 'target')}"#{(node.option? 'autoplay') ? (boolean_attribute 'autoplay', xml) : nil}#{(node.option? 'nocontrols') ? nil : (boolean_attribute 'controls', xml)}#{(node.option? 'loop') ? (boolean_attribute 'loop', xml) : nil}>
Your browser does not support the audio tag.
</audio>
</div>
</div>)
  end

  def boolean_attribute name, xml
    xml ? %( #{name}="#{name}") : %( #{name})
  end

  def template
    :invoke_result
  end
end

class BlockVideoTemplate < BaseTemplate
  def result(node)
    xml = node.document.attr? 'htmlsyntax', 'xml'
    id_attribute = node.id ? %( id="#{node.id}") : nil
    classes = ['videoblock', node.style, node.role].compact
    class_attribute = %( class="#{classes * ' '}")
    title_element = node.title? ? %(\n<div class="title">#{node.captioned_title}</div>) : nil
    width_attribute = (node.attr? 'width') ? %( width="#{node.attr 'width'}") : nil
    height_attribute = (node.attr? 'height') ? %( height="#{node.attr 'height'}") : nil
    case node.attr 'poster'
    when 'vimeo'
      start_anchor = (node.attr? 'start') ? "#at=#{node.attr 'start'}" : nil
      delimiter = '?'
      autoplay_param = (node.option? 'autoplay') ? "#{delimiter}autoplay=1" : nil
      delimiter = '&amp;' if autoplay_param
      loop_param = (node.option? 'loop') ? "#{delimiter}loop=1" : nil
      %(<div#{id_attribute}#{class_attribute}>#{title_element}
<div class="content">
<iframe#{width_attribute}#{height_attribute} src="//player.vimeo.com/video/#{node.attr 'target'}#{start_anchor}#{autoplay_param}#{loop_param}" frameborder="0"#{boolean_attribute 'webkitAllowFullScreen', xml}#{boolean_attribute 'mozallowfullscreen', xml}#{boolean_attribute 'allowFullScreen', xml}></iframe>
</div>
</div>)
    when 'youtube'
      start_param = (node.attr? 'start') ? "&amp;start=#{node.attr 'start'}" : nil
      end_param = (node.attr? 'end') ? "&amp;end=#{node.attr 'end'}" : nil
      autoplay_param = (node.option? 'autoplay') ? '&amp;autoplay=1' : nil
      loop_param = (node.option? 'loop') ? '&amp;loop=1' : nil
      controls_param = (node.option? 'nocontrols') ? '&amp;controls=0' : nil
      %(<div#{id_attribute}#{class_attribute}>#{title_element}
<div class="content">
<iframe#{width_attribute}#{height_attribute} src="//www.youtube.com/embed/#{node.attr 'target'}?rel=0#{start_param}#{end_param}#{autoplay_param}#{loop_param}#{controls_param}" frameborder="0"#{(node.option? 'nofullscreen') ? nil : (boolean_attribute 'allowfullscreen', xml)}></iframe>
</div>
</div>)
    else 
      poster_attribute = %(#{poster = node.attr 'poster'}).empty? ? nil : %( poster="#{node.media_uri poster}")
      %(<div#{id_attribute}#{class_attribute}>#{title_element}
<div class="content">
<video src="#{node.media_uri(node.attr 'target')}"#{width_attribute}#{height_attribute}#{poster_attribute}#{(node.option? 'autoplay') ? (boolean_attribute 'autoplay', xml) : nil}#{(node.option? 'nocontrols') ? nil : (boolean_attribute 'controls', xml)}#{(node.option? 'loop') ? (boolean_attribute 'loop', xml) : nil}>
Your browser does not support the video tag.
</video>
</div>
</div>)
    end
  end

  def boolean_attribute name, xml
    xml ? %( #{name}="#{name}") : %( #{name})
  end

  def template
    :invoke_result
  end
end

class BlockRulerTemplate < BaseTemplate
  def result(node)
    (node.document.attr? 'htmlsyntax', 'xml') ? '<hr/>' : '<hr>'
  end

  def template
    :invoke_result
  end
end

class BlockPageBreakTemplate < BaseTemplate
  def result(node)
    %(<div style="page-break-after: always;"></div>)
  end

  def template
    :invoke_result
  end
end

class InlineBreakTemplate < BaseTemplate
  def result(node)
    (node.document.attr? 'htmlsyntax', 'xml') ? %(#{node.text}<br/>\n) : %(#{node.text}<br>\n)
  end

  def template
    :invoke_result
  end
end

class InlineCalloutTemplate < BaseTemplate
  def result(node)
    if node.document.attr? 'icons', 'font'
      %(<i class="conum" data-value="#{node.text}"></i><b>(#{node.text})</b>)
    elsif node.document.attr? 'icons'
      src = node.icon_uri("callouts/#{node.text}")
      %(<img src="#{src}" alt="#{node.text}"#{node.short_tag_slash}>)
    else
      "<b>(#{node.text})</b>"
    end
  end

  def template
    :invoke_result
  end
end

class InlineQuotedTemplate < BaseTemplate
  NO_TAGS = [nil, nil, nil]

  QUOTE_TAGS = {
    :emphasis => ['<em>', '</em>', true],
    :strong => ['<strong>', '</strong>', true],
    :monospaced => ['<code>', '</code>', true],
    :superscript => ['<sup>', '</sup>', true],
    :subscript => ['<sub>', '</sub>', true],
    :double => ['&#8220;', '&#8221;', false],
    :single => ['&#8216;', '&#8217;', false],
    :asciimath => INLINE_MATH_DELIMITERS[:asciimath] + [false],
    :latexmath => INLINE_MATH_DELIMITERS[:latexmath] + [false]
  }

  def quote_text(text, type, id, role)
    open, close, is_tag = QUOTE_TAGS[type] || NO_TAGS
    anchor = id.nil? ? nil : %(<a id="#{id}"></a>)
    if role
      if is_tag
        quoted_text = %(#{open.chop} class="#{role}">#{text}#{close})
      else
        quoted_text = %(<span class="#{role}">#{open}#{text}#{close}</span>)
      end
    elsif open.nil?
      quoted_text = text
    else
      quoted_text = %(#{open}#{text}#{close})
    end

    anchor.nil? ? quoted_text : %(#{anchor}#{quoted_text})
  end

  def result(node)
    quote_text(node.text, node.type, node.id, node.role)
  end

  def template
    :invoke_result
  end
end

class InlineButtonTemplate < BaseTemplate
  def result(node)
    %(<b class="button">#{node.text}</b>)
  end

  def template
    :invoke_result
  end
end

class InlineKbdTemplate < BaseTemplate
  def result(node)
    keys = node.attr 'keys'
    if keys.size == 1
      %(<kbd>#{keys.first}</kbd>)
    else
      key_combo = keys.map{|key| %(<kbd>#{key}</kbd>+) }.join.chop
      %(<kbd class="keyseq">#{key_combo}</kbd>)
    end
  end

  def template
    :invoke_result
  end
end

class InlineMenuTemplate < BaseTemplate
  def menu(menu, submenus, menuitem)
    if !submenus.empty?
      submenu_path = submenus.map{|submenu| %(<span class="submenu">#{submenu}</span>&#160;&#9656; ) }.join.chop
      %(<span class="menuseq"><span class="menu">#{menu}</span>&#160;&#9656; #{submenu_path} <span class="menuitem">#{menuitem}</span></span>)
    elsif !menuitem.nil?
      %(<span class="menuseq"><span class="menu">#{menu}</span>&#160;&#9656; <span class="menuitem">#{menuitem}</span></span>)
    else
      %(<span class="menu">#{menu}</span>)
    end
  end

  def result(node)
    menu(node.attr('menu'), node.attr('submenus'), node.attr('menuitem'))
  end

  def template
    :invoke_result
  end
end

class InlineAnchorTemplate < BaseTemplate
  def anchor(target, text, type, document, node)
    case type
    when :xref
      refid = (node.attr 'refid') || target
      if text.nil?
        # FIXME this seems like it should be prepared already
        text = document.references[:ids].fetch(refid, "[#{refid}]") if text.nil?
      end
      %(<a href="#{target}">#{text}</a>)
    when :ref
      %(<a id="#{target}"></a>)
    when :link
      %(<a href="#{target}"#{node.role? ? " class=\"#{node.role}\"" : nil}#{(node.attr? 'window') ? " target=\"#{node.attr 'window'}\"" : nil}>#{text}</a>)
    when :bibref
      %(<a id="#{target}"></a>[#{target}])
    end
  end

  def result(node)
    anchor(node.target, node.text, node.type, node.document, node)
  end

  def template
    :invoke_result
  end
end

class InlineImageTemplate < BaseTemplate
  def image(target, type, node)
    if type == 'icon' && (node.document.attr? 'icons', 'font') 
      style_class = "icon-#{target}"
      if node.attr? 'size'
        style_class = "#{style_class} icon-#{node.attr 'size'}"
      end
      if node.attr? 'rotate'
        style_class = "#{style_class} icon-rotate-#{node.attr 'rotate'}"
      end
      if node.attr? 'flip'
        style_class = "#{style_class} icon-flip-#{node.attr 'flip'}"
      end
      title_attribute = (node.attr? 'title') ? %( title="#{node.attr 'title'}") : nil
      img = %(<i class="#{style_class}"#{title_attribute}></i>)
    elsif type == 'icon' && !(node.document.attr? 'icons')
      img = "[#{node.attr 'alt'}]"
    else
      if type == 'icon'
        resolved_target = node.icon_uri target
      else
        resolved_target = node.image_uri target
      end

      attrs = ['alt', 'width', 'height', 'title'].map {|name|
        if node.attr? name
          %( #{name}="#{node.attr name}")
        else
          nil
        end
      }.join

      img = %(<img src="#{resolved_target}"#{attrs}#{node.short_tag_slash}>)
    end

    if node.attr? 'link'
      img = %(<a class="image" href="#{node.attr 'link'}"#{(node.attr? 'window') ? " target=\"#{node.attr 'window'}\"" : nil}>#{img}</a>)
    end

    if node.role?
      style_classes = %(#{type} #{node.role})
    else
      style_classes = type
    end

    style_attr = (node.attr? 'float') ? %( style="float: #{node.attr 'float'}") : nil

    %(<span class="#{style_classes}"#{style_attr}>#{img}</span>)
  end

  def result(node)
    image(node.target, node.type, node)
  end

  def template
    :invoke_result
  end
end

class InlineFootnoteTemplate < BaseTemplate
  def result(node)
    index = node.attr :index
    if node.type == :xref
      %(<span class="footnoteref">[<a class="footnote" href="#_footnote_#{index}" title="View footnote.">#{index}</a>]</span>)
    else
      id_attribute = node.id ? %( id="_footnote_#{node.id}") : nil
      %(<span class="footnote"#{id_attribute}>[<a id="_footnoteref_#{index}" class="footnote" href="#_footnote_#{index}" title="View footnote.">#{index}</a>]</span>)
    end
  end

  def template
    :invoke_result
  end
end

class InlineIndextermTemplate < BaseTemplate
  def result(node)
    node.type == :visible ? node.text : ''
  end

  def template
    :invoke_result
  end
end

end # module HTML5
end # module Asciidoctor
