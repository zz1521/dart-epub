import 'dart:async';

import 'package:archive/archive.dart';

import 'entities/epub_book.dart';
import 'entities/epub_byte_content_file.dart';
import 'entities/epub_chapter.dart';
import 'entities/epub_content.dart';
import 'entities/epub_content_file.dart';
import 'entities/epub_text_content_file.dart';
import 'readers/content_reader.dart';
import 'readers/schema_reader.dart';
import 'ref_entities/epub_book_ref.dart';
import 'ref_entities/epub_byte_content_file_ref.dart';
import 'ref_entities/epub_chapter_ref.dart';
import 'ref_entities/epub_content_file_ref.dart';
import 'ref_entities/epub_content_ref.dart';
import 'ref_entities/epub_text_content_file_ref.dart';
import 'schema/opf/epub_metadata_creator.dart';

class EpubReader {
  /// Opens the book asynchronously without reading its content. Holds the handle to the EPUB file.
  static Future<EpubBookRef> openBook(List<int> bytes) async {
    Archive epubArchive = new ZipDecoder().decodeBytes(bytes);

    EpubBookRef bookRef = new EpubBookRef(epubArchive);
    bookRef.FilePath = "";
    bookRef.Schema = await SchemaReader.readSchema(epubArchive);
    bookRef.Title = bookRef.Schema.Package.Metadata.Titles
        .firstWhere((String name) => true, orElse: () => "");
    bookRef.AuthorList = bookRef.Schema.Package.Metadata.Creators
        .map((EpubMetadataCreator creator) => creator.Creator)
        .toList();
    bookRef.Author = bookRef.AuthorList.join(", ");
    bookRef.Content = await ContentReader.parseContentMap(bookRef);
    return bookRef;
  }

  static EpubBookRef openBookSync(List<int> bytes) {
    Archive epubArchive = new ZipDecoder().decodeBytes(bytes);

    EpubBookRef bookRef = new EpubBookRef(epubArchive);
    bookRef.FilePath = "";
    bookRef.Schema = SchemaReader.readSchemaSync(epubArchive);
    bookRef.Title = bookRef.Schema.Package.Metadata.Titles
        .firstWhere((String name) => true, orElse: () => "");
    bookRef.AuthorList = bookRef.Schema.Package.Metadata.Creators
        .map((EpubMetadataCreator creator) => creator.Creator)
        .toList();
    bookRef.Author = bookRef.AuthorList.join(", ");
    bookRef.Content = ContentReader.parseContentMap(bookRef);
    return bookRef;
  }

  /// Opens the book asynchronously and reads all of its content into the memory. Does not hold the handle to the EPUB file.
  static Future<EpubBook> readBook(List<int> bytes) async {
    EpubBook result = new EpubBook();

    EpubBookRef epubBookRef = await openBook(bytes);
    result.FilePath = epubBookRef.FilePath;
    result.Schema = epubBookRef.Schema;
    result.Title = epubBookRef.Title;
    result.AuthorList = epubBookRef.AuthorList;
    result.Author = epubBookRef.Author;
    result.Content = await readContent(epubBookRef.Content);
    result.CoverImage = await epubBookRef.readCover();
    List<EpubChapterRef> chapterRefs = await epubBookRef.getChapters();
    result.Chapters = await readChapters(chapterRefs);

    return result;
  }

  static EpubBook readBookSync(List<int> bytes) {
    EpubBook result = new EpubBook();

    EpubBookRef epubBookRef = openBookSync(bytes);
    result.FilePath = epubBookRef.FilePath;
    result.Schema = epubBookRef.Schema;
    result.Title = epubBookRef.Title;
    result.AuthorList = epubBookRef.AuthorList;
    result.Author = epubBookRef.Author;
    result.Content = readContentSync(epubBookRef.Content);
    result.CoverImage = epubBookRef.readCoverSync();
    List<EpubChapterRef> chapterRefs = epubBookRef.getChaptersSync();
    result.Chapters = readChaptersSync(chapterRefs);

    return result;
  }

  static Future<EpubContent> readContent(EpubContentRef contentRef) async {
    EpubContent result = new EpubContent();
    result.Html = await readTextContentFiles(contentRef.Html);
    result.Css = await readTextContentFiles(contentRef.Css);
    result.Images = await readByteContentFiles(contentRef.Images);
    result.Fonts = await readByteContentFiles(contentRef.Fonts);
    result.AllFiles = new Map<String, EpubContentFile>();

    result.Html.forEach((String key, EpubTextContentFile value) {
      result.AllFiles[key] = value;
    });
    result.Css.forEach((String key, EpubTextContentFile value) {
      result.AllFiles[key] = value;
    });

    result.Images.forEach((String key, EpubByteContentFile value) {
      result.AllFiles[key] = value;
    });
    result.Fonts.forEach((String key, EpubByteContentFile value) {
      result.AllFiles[key] = value;
    });

    await Future.forEach(contentRef.AllFiles.keys, (key) async {
      if (!result.AllFiles.containsKey(key)) {
        result.AllFiles[key] =
        await readByteContentFile(contentRef.AllFiles[key]);
      }
    });

    return result;
  }

  static EpubContent readContentSync(EpubContentRef contentRef) {
    EpubContent result = new EpubContent();
    result.Html = readTextContentFilesSync(contentRef.Html);
    result.Css = readTextContentFilesSync(contentRef.Css);
    result.Images = readByteContentFilesSync(contentRef.Images);
    result.Fonts = readByteContentFilesSync(contentRef.Fonts);
    result.AllFiles = new Map<String, EpubContentFile>();

    result.Html.forEach((String key, EpubTextContentFile value) {
      result.AllFiles[key] = value;
    });
    result.Css.forEach((String key, EpubTextContentFile value) {
      result.AllFiles[key] = value;
    });

    result.Images.forEach((String key, EpubByteContentFile value) {
      result.AllFiles[key] = value;
    });
    result.Fonts.forEach((String key, EpubByteContentFile value) {
      result.AllFiles[key] = value;
    });

    contentRef.AllFiles.keys.forEach((key) {
      if (!result.AllFiles.containsKey(key)) {
        result.AllFiles[key] =
            readByteContentFileSync(contentRef.AllFiles[key]);
      }
    });

    return result;
  }

  static Map<String, EpubTextContentFile> readTextContentFilesSync(
      Map<String, EpubTextContentFileRef> textContentFileRefs) {
    Map<String, EpubTextContentFile> result =
    new Map<String, EpubTextContentFile>();

    textContentFileRefs.keys.forEach((key) {
      EpubContentFileRef value = textContentFileRefs[key];
      EpubTextContentFile textContentFile = new EpubTextContentFile();
      textContentFile.FileName = value.FileName;
      textContentFile.ContentType = value.ContentType;
      textContentFile.ContentMimeType = value.ContentMimeType;
      textContentFile.Content = value.readContentAsTextSync();
      result[key] = textContentFile;
    });
    return result;
  }
  static Future<Map<String, EpubTextContentFile>> readTextContentFiles(
      Map<String, EpubTextContentFileRef> textContentFileRefs) async {
    Map<String, EpubTextContentFile> result =
    new Map<String, EpubTextContentFile>();

    await Future.forEach(textContentFileRefs.keys, (key) async {
      EpubContentFileRef value = textContentFileRefs[key];
      EpubTextContentFile textContentFile = new EpubTextContentFile();
      textContentFile.FileName = value.FileName;
      textContentFile.ContentType = value.ContentType;
      textContentFile.ContentMimeType = value.ContentMimeType;
      textContentFile.Content = await value.readContentAsText();
      result[key] = textContentFile;
    });
    return result;
  }

  static Map<String, EpubByteContentFile> readByteContentFilesSync(
      Map<String, EpubByteContentFileRef> byteContentFileRefs) {
    Map<String, EpubByteContentFile> result =
    new Map<String, EpubByteContentFile>();
    byteContentFileRefs.keys.forEach((key) {
      result[key] = readByteContentFileSync(byteContentFileRefs[key]);
    });
    return result;
  }
  static Future<Map<String, EpubByteContentFile>> readByteContentFiles(
      Map<String, EpubByteContentFileRef> byteContentFileRefs) async {
    Map<String, EpubByteContentFile> result =
        new Map<String, EpubByteContentFile>();
    await Future.forEach(byteContentFileRefs.keys, (key) async {
      result[key] = await readByteContentFile(byteContentFileRefs[key]);
    });
    return result;
  }


  static EpubByteContentFile readByteContentFileSync(
      EpubContentFileRef contentFileRef) {
    EpubByteContentFile result = new EpubByteContentFile();

    result.FileName = contentFileRef.FileName;
    result.ContentType = contentFileRef.ContentType;
    result.ContentMimeType = contentFileRef.ContentMimeType;
    result.Content = contentFileRef.readContentAsBytesSync();

    return result;
  }
  static Future<EpubByteContentFile> readByteContentFile(
      EpubContentFileRef contentFileRef) async {
    EpubByteContentFile result = new EpubByteContentFile();

    result.FileName = contentFileRef.FileName;
    result.ContentType = contentFileRef.ContentType;
    result.ContentMimeType = contentFileRef.ContentMimeType;
    result.Content = await contentFileRef.readContentAsBytes();

    return result;
  }

  static List<EpubChapter> readChaptersSync(
      List<EpubChapterRef> chapterRefs) {
    List<EpubChapter> result = new List<EpubChapter>();
    chapterRefs.forEach((EpubChapterRef chapterRef) {
      EpubChapter chapter = new EpubChapter();

      chapter.Title = chapterRef.Title;
      chapter.ContentFileName = chapterRef.ContentFileName;
      chapter.Anchor = chapterRef.Anchor;
      chapter.HtmlContent = chapterRef.readHtmlContentSync();
      chapter.SubChapters = readChaptersSync(chapterRef.SubChapters);

      result.add(chapter);
    });
    return result;
  }
  static Future<List<EpubChapter>> readChapters(
      List<EpubChapterRef> chapterRefs) async {
    List<EpubChapter> result = new List<EpubChapter>();
    await Future.forEach(chapterRefs, (EpubChapterRef chapterRef) async {
      EpubChapter chapter = new EpubChapter();

      chapter.Title = chapterRef.Title;
      chapter.ContentFileName = chapterRef.ContentFileName;
      chapter.Anchor = chapterRef.Anchor;
      chapter.HtmlContent = await chapterRef.readHtmlContent();
      chapter.SubChapters = await readChapters(chapterRef.SubChapters);

      result.add(chapter);
    });
    return result;
  }
}
