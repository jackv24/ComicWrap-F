import 'package:comicwrap_f/models/collection_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ComicInfoCard extends StatefulWidget {
  final ComicDocumentModel comicDoc;

  const ComicInfoCard(this.comicDoc, {Key? key}) : super(key: key);

  @override
  _ComicInfoCardState createState() => _ComicInfoCardState();
}

class _ComicInfoCardState extends State<ComicInfoCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String? coverImageUrl = widget.comicDoc.coverImageUrl;

    // If cover url is relative, make it absolute
    if (coverImageUrl != null && !coverImageUrl.startsWith('http')) {
      final scrapeUrl = widget.comicDoc.scrapeUrl;
      if (scrapeUrl?.isNotEmpty ?? false) {
        coverImageUrl = scrapeUrl! + coverImageUrl;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 210.0 / 297.0,
          child: Material(
            color: Colors.white,
            elevation: 5.0,
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
            clipBehavior: Clip.antiAlias,
            child:
                /*OpenContainer(
              closedBuilder: (context, openFunc) {
                return */
                CardImageButton(
              coverImageUrl: coverImageUrl,
              onTap: () => {}, //openFunc(),
            ) /*;
              },
              openBuilder: (context, closeFunc) =>
                  ComicPage(snapshot.data, coverImageUrl),
            )*/
            ,
          ),
        ),
        SizedBox(height: 5.0),
        Text(
          widget.comicDoc.name,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.subtitle1,
        ),
        SizedBox(height: 2.0),
        Text(
          '3 days ago',
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.subtitle2,
        ),
      ],
    );
  }
}

class CardImageButton extends StatefulWidget {
  final String? coverImageUrl;
  final Function()? onTap;

  const CardImageButton({Key? key, this.coverImageUrl, this.onTap})
      : super(key: key);

  @override
  _CardImageButtonState createState() => _CardImageButtonState();
}

class _CardImageButtonState extends State<CardImageButton> {
  FileInfo? _cachedImage;
  DownloadProgress? _imageDownloadProgress;

  @override
  void initState() {
    // Stream for cached cover image
    if (widget.coverImageUrl != null) {
      DefaultCacheManager()
          .getImageFile(widget.coverImageUrl!, withProgress: true)
          .listen((fileResponse) {
        if (fileResponse is FileInfo) {
          setState(() {
            _cachedImage = fileResponse;
            _imageDownloadProgress = null;
          });
        } else if (fileResponse is DownloadProgress) {
          setState(() {
            _imageDownloadProgress = fileResponse;
          });
        }
      });
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedImage == null) {
      if (_imageDownloadProgress == null) {
        return InkWell(
          onTap: widget.onTap,
          child: Icon(Icons.error, color: Colors.red),
        );
      } else {
        return Stack(
          alignment: AlignmentDirectional.bottomCenter,
          children: [
            LinearProgressIndicator(
              value: _imageDownloadProgress!.progress,
              minHeight: 8.0,
            ),
          ],
        );
      }
    } else {
      return Ink.image(
        image: FileImage(_cachedImage!.file),
        fit: BoxFit.cover,
        child: InkWell(
          onTap: widget.onTap,
        ),
      );
    }
  }
}
