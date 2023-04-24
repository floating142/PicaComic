import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:pica_comic/views/reader/reading_logic.dart';
import 'package:flutter/material.dart';
import '../../base.dart';
import '../../eh_network/get_gallery_id.dart';
import '../../network/methods.dart';
import '../eh_views/eh_widgets/eh_image_provider/eh_cached_image.dart';
import '../jm_views/jm_image_provider/jm_cached_image.dart';
import '../widgets/cf_image_widgets.dart';
import '../widgets/scrollable_list/src/scrollable_positioned_list.dart';
import '../widgets/widgets.dart';
import 'package:get/get.dart';
import 'reading_type.dart';

///构建从上至下(连续)阅读方式
Widget buildGallery(ComicReadingPageLogic comicReadingPageLogic, ReadingType type, String target) {
  return ScrollablePositionedList.builder(
    itemScrollController: comicReadingPageLogic.scrollController,
    itemPositionsListener: comicReadingPageLogic.scrollListener,
    itemCount: comicReadingPageLogic.urls.length,
    addSemanticIndexes: false,
    scrollController: comicReadingPageLogic.cont,
    minCacheExtent: 20,
    itemBuilder: (context, index) {

      precacheComicImage(comicReadingPageLogic, type, context, index+1, target);

      //加载eh图片
      if (type == ReadingType.ehentai && ! comicReadingPageLogic.downloaded) {
        final height = Get.width * 1.42;
        return Image(
          image: EhCachedImageProvider(comicReadingPageLogic.urls[index]),
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.fill,
          frameBuilder: (context, widget, i, b) {
            return widget;
          },
          loadingBuilder: (context, widget, event) {
            if (event == null) {
              return widget;
            } else {
              return SizedBox(
                height: height,
                child: Center(
                    child: event.expectedTotalBytes != null && event.expectedTotalBytes != null
                        ? CircularProgressIndicator(
                      value: event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                      backgroundColor: Colors.white12,
                    )
                        : const CircularProgressIndicator()),
              );
            }
          },
          errorBuilder: (context, s, d) => SizedBox(
            height: height,
            child: const Center(
              child: Icon(
                Icons.error,
                color: Colors.white12,
              ),
            ),
          ),
        );
      }

      if (comicReadingPageLogic.downloaded) {
        //加载已下载的图片
        var id = target;
        if(type == ReadingType.ehentai){
          id = getGalleryId(target);
        }
        return Image.file(
          downloadManager.getImage(id, comicReadingPageLogic.order, index),
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.fill,
        );
      } else {
        //加载未下载的图片
        final height = Get.width * 1.42;
        if(type == ReadingType.picacg){
          //加载哔咔图片
          return CfCachedNetworkImage(
            imageUrl: getImageUrl(comicReadingPageLogic.urls[index]),
            width: MediaQuery.of(context).size.width,
            fit: BoxFit.fill,
            progressIndicatorBuilder: (context, s, progress) => SizedBox(
              height: height,
              child: Center(
                  child: CircularProgressIndicator(
                    value: progress.progress,
                    backgroundColor: Colors.white12,
                  )),
            ),
            errorWidget: (context, s, d) => SizedBox(
              height: height,
              child: const Center(
                child: Icon(
                  Icons.error,
                  color: Colors.white12,
                ),
              ),
            ),
          );
        }else{
          //加载禁漫图片
          return Image(
            image: JmCachedImageProvider(comicReadingPageLogic.urls[index], target),
            width: MediaQuery.of(context).size.width,
            fit: BoxFit.fitWidth,
            loadingBuilder: (context, widget, event) {
              if (event == null) {
                return widget;
              } else {
                return SizedBox(
                  height: height,
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
            },
            errorBuilder: (context, s, d) => SizedBox(
              height: height,
              child: const Center(
                child: Icon(
                  Icons.error,
                  color: Colors.white12,
                ),
              ),
            ),
          );
        }
      }
    },
  );
}

///构建漫画图片
Widget buildComicView(ComicReadingPageLogic comicReadingPageLogic, ReadingType type, String target, List<String> eps) {
  if (appdata.settings[9] != "4") {
    return Positioned(
        top: 0,
        left: 0,
        bottom: 0,
        right: 0,
        child: AbsorbPointer(
          absorbing: comicReadingPageLogic.tools,
          child: Listener(
            //监听鼠标滚轮
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                comicReadingPageLogic.controller.jumpToPage(pointerSignal.scrollDelta.dy > 0
                    ? comicReadingPageLogic.index + 1
                    : comicReadingPageLogic.index - 1);
              }
            },
            child: PhotoViewGallery.builder(
              reverse: appdata.settings[9] == "2",
              scrollDirection: appdata.settings[9] != "3" ? Axis.horizontal : Axis.vertical,
              itemCount: comicReadingPageLogic.urls.length + 2,
              builder: (BuildContext context, int index) {

                ImageProvider? imageProvider;
                if (index != 0 && index != comicReadingPageLogic.urls.length + 1){
                  if (type == ReadingType.ehentai && !comicReadingPageLogic.downloaded){
                    imageProvider = EhCachedImageProvider(comicReadingPageLogic.urls[index - 1]);
                  }else if (comicReadingPageLogic.downloaded){
                    var id = target;
                    if(type == ReadingType.ehentai){
                      id = getGalleryId(target);
                    }
                    imageProvider = FileImage(downloadManager.getImage(
                        id, comicReadingPageLogic.order, index - 1));
                  }else if(type == ReadingType.picacg){
                    imageProvider = CachedNetworkImageProvider(
                        getImageUrl(comicReadingPageLogic.urls[index - 1]));
                  }else{
                    imageProvider = JmCachedImageProvider(comicReadingPageLogic.urls[index - 1], target);
                  }
                }else {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: const AssetImage("images/black.png"),
                  );
                }

                precacheComicImage(comicReadingPageLogic, type, context, index, target);

                return PhotoViewGalleryPageOptions(
                  minScale: PhotoViewComputedScale.contained * 0.9,
                  imageProvider: imageProvider,
                  initialScale: PhotoViewComputedScale.contained,
                  heroAttributes: PhotoViewHeroAttributes(
                      tag: "$index/${comicReadingPageLogic.urls.length}"),
                );
              },
              pageController: comicReadingPageLogic.controller,
              loadingBuilder: (context, event) => DecoratedBox(
                decoration: const BoxDecoration(color: Colors.black),
                child: Center(
                  child: SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.white12,
                      value: event == null
                          ? 0
                          : event.cumulativeBytesLoaded / (event.expectedTotalBytes??1000000000000),
                    ),
                  ),
                ),
              ),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              onPageChanged: (i) {
                if (i == 0) {
                  if (type == ReadingType.ehentai) {
                    comicReadingPageLogic.controller.jumpToPage(1);
                    showMessage(Get.context, "已经是第一页了");
                    return;
                  }
                  if (comicReadingPageLogic.order != 1) {
                    comicReadingPageLogic.order -= 1;
                    comicReadingPageLogic.urls.clear();
                    comicReadingPageLogic.isLoading = true;
                    comicReadingPageLogic.tools = false;
                    comicReadingPageLogic.update();
                  } else {
                    comicReadingPageLogic.controller.jumpToPage(1);
                    showMessage(Get.context, "已经是第一章了");
                  }
                } else if (i == comicReadingPageLogic.urls.length + 1) {
                  if (type == ReadingType.ehentai) {
                    comicReadingPageLogic.controller.jumpToPage(i - 1);
                    showMessage(Get.context, "已经是最后一页了");
                    return;
                  }
                  if (comicReadingPageLogic.order != eps.length - 1) {
                    comicReadingPageLogic.order += 1;
                    comicReadingPageLogic.urls.clear();
                    comicReadingPageLogic.isLoading = true;
                    comicReadingPageLogic.tools = false;
                    comicReadingPageLogic.update();
                  } else {
                    comicReadingPageLogic.controller.jumpToPage(i - 1);
                    showMessage(Get.context, "已经是最后一章了");
                  }
                } else {
                  comicReadingPageLogic.index = i;
                  comicReadingPageLogic.update();
                }
              },
            ),
          ),
        ));
  } else {
    return Positioned(
        top: 0,
        bottom: 0,
        left: 0,
        right: 0,
        child: AbsorbPointer(
          absorbing: comicReadingPageLogic.tools,
          child: InteractiveViewer(
              transformationController: comicReadingPageLogic.transformationController,
              maxScale: GetPlatform.isDesktop ? 1.0 : 2.5,
              child: AbsorbPointer(
                absorbing: true, //使用控制器控制滚动
                child: SizedBox(
                    width: MediaQuery.of(Get.context!).size.width,
                    height: MediaQuery.of(Get.context!).size.height,
                    child: buildGallery(comicReadingPageLogic, type, target)),
              )),
        ));
  }
}

var _loadingImages = 0;

///预加载图片
void precacheComicImage(ComicReadingPageLogic comicReadingPageLogic,ReadingType type,BuildContext context, int index, String target){
  if(_loadingImages <= 1) {
    _loadingImages++;
  }else{
    return;
  }
  if (index < comicReadingPageLogic.urls.length && type == ReadingType.ehentai && !comicReadingPageLogic.downloaded) {
    precacheImage(
        EhCachedImageProvider(comicReadingPageLogic.urls[index]), context);
  } else if (index < comicReadingPageLogic.urls.length && type == ReadingType.picacg &&
      !comicReadingPageLogic.downloaded) {
    precacheImage(
        CachedNetworkImageProvider(getImageUrl(comicReadingPageLogic.urls[index])),
        context);
  } else if(index < comicReadingPageLogic.urls.length && type == ReadingType.jm &&
      !comicReadingPageLogic.downloaded){
    precacheImage(JmCachedImageProvider(comicReadingPageLogic.urls[index], target), context);
  }else if (index < comicReadingPageLogic.urls.length &&
      comicReadingPageLogic.downloaded) {
    var id = target;
    if(type == ReadingType.ehentai){
      id = getGalleryId(target);
    }
    precacheImage(
        FileImage(
            downloadManager.getImage(id, comicReadingPageLogic.order, index)),
        context);
  }
}