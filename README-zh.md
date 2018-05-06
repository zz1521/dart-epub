# dart-epub
复制于[dart-epub by Colin Nelson](https://github.com/orthros/dart-epub)

在中国有一些epub文件无法正确解析，因此我移除了解析xml的namespace(http://www.idpf.org/2007/ops)限制条件。

增加了对应的sync方法。

启发于[C# Epub Reader](https://github.com/versfx/EpubReader)的Dart版ePub解析器

此项目不依赖```dart:io```，因此可用于桌面、web、移动端的开发。

## 安装

把扩展添加到pubspec.yaml文件的```dependencies``` 部分

```
dependencies:
  epub:
    git: https://github.com/creatint/dart-epub
```

## 例子
```dart

//把文件数据读进内存
String fileName = "hittelOnGoldMines.epub";
String fullPath = path.join(io.Directory.current.path, fileName);
var targetFile = new io.File(fullPath);
List<int> bytes = await targetFile.readAsBytes();


// 打开并书籍，把全部内容读进内存
// Opens a book and reads all of its content into the memory
EpubBook epubBook = await EpubReader.readBook(bytes);
            
// 常用属性

// 书籍标题
String title = epubBook.Title;

// 书籍作者 (逗号分割)
String author = epubBook.Author;

// 书籍作者 (作者姓名列表)
List<String> authors = epubBook.AuthorList;

// 书籍封面图片 (无图为null)
Image coverImage = epubBook.CoverImage;

            
// 章节

// 遍历章节
epubBook.Chapters.forEach((EpubChapter chapter) {
  // 章节标题
  String chapterTitle = chapter.Title;
              
  /// 当前章节的HTML文档
  String chapterHtmlContent = chapter.HtmlContent;

  /// 嵌套的章节
  List<EpubChapter> subChapters = chapter.SubChapters;
});

            
// 内容

// 书籍内容 (HTML文件、样式、图片、字体等)
EpubContent bookContent = epubBook.Content;

            
// 图片

// 书籍图片 （key为文件名）
Map<String, EpubByteContentFile> images = bookContent.Images;

EpubByteContentFile firstImage = images.values.first;

// 内容类型 (例如 EpubContentType.IMAGE_JPEG, EpubContentType.IMAGE_PNG)
EpubContentType contentType = firstImage.ContentType;

// MIME类型 (例如 "image/jpeg", "image/png")
String mimeContentType = firstImage.ContentMimeType;

// HTML和CSS

// 全部XHTML文件 （key为文件名）
Map<String, EpubTextContentFile> htmlFiles = bookContent.Html;

// 全部CSS文件 （key为文件名）
Map<String, EpubTextContentFile> cssFiles = bookContent.Css;

// Entire HTML content of the book
// 书籍全部HTML 内容
htmlFiles.values.forEach((EpubTextContentFile htmlFile) {
  String htmlContent = htmlFile.Content;
});

// 书籍全部css内容
cssFiles.values.forEach((EpubTextContentFile cssFile){
  String cssContent = cssFile.Content;
});


// 其他内容

// 书籍字体 （文件名为key）
Map<String, EpubByteContentFile> fonts = bookContent.Fonts;

// 书籍全部文件 （包括html、css、images、font和其他类型文件）
Map<String, EpubContentFile> allFiles = bookContent.AllFiles;



// 访问原始架构信息 

// EPUB OPF 数据
EpubPackage package = epubBook.Schema.Package;

// 遍历书籍编辑人员
package.Metadata.Contributors.forEach((EpubMetadataContributor contributor){
  String contributorName = contributor.Contributor;
  String contributorRole = contributor.Role;
});

// EPUB NCX 数据
EpubNavigation navigation = epubBook.Schema.Navigation;

// 遍历 NCX 元数据
navigation.Head.Metadata.forEach((EpubNavigationHeadMeta meta){
  String metadataItemName = meta.Name;
  String metadataItemContent = meta.Content;
});
```