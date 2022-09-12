import 'package:flutter/material.dart';

class HorizontalTypeHead<T extends HorizontalTypeHeadModel> extends StatefulWidget {
  const HorizontalTypeHead(
      {Key? key,
      required this.onLookup,
      required this.onSelected,
      this.selectedModelBuilder,
      this.startLookupLenght = 3,
      this.initialHeight = 80,
      this.expandedHeight = 284,
      this.resultWidth,
      this.smallerResultTitle = false,
      this.rawItemBuilder,
      this.containerDecoration,
      this.scrollController,
      this.resultImageBoxFit,
      this.textInputStyle,
      this.inputDecoration})
      : super(key: key);

  final double initialHeight;
  final double expandedHeight;
  final double? resultWidth;
  final bool smallerResultTitle;
  final Future<Iterable<T>> Function(String value) onLookup;
  final Function(T model) onSelected;
  final HorizontalTypeHeadResultWidget? selectedModelBuilder;
  final ScrollController? scrollController;
  final int startLookupLenght;
  final Widget Function(BuildContext, dynamic suggestionModel)? rawItemBuilder;
  final BoxDecoration? containerDecoration;
  final InputDecoration? inputDecoration;
  final BoxFit? resultImageBoxFit;
  final TextStyle? textInputStyle;

  @override
  State<HorizontalTypeHead> createState() => _HorizontalTypeHeadState<T>();
}

class _HorizontalTypeHeadState<T extends HorizontalTypeHeadModel>
    extends State<HorizontalTypeHead<T>> {
  @override
  void initState() {
    _height = widget.initialHeight;
    super.initState();
  }

  double? _height;
  final List<T> _data = [];
  Iterable<T> _newData = [];
  bool _isBoxOpen = false;
  bool _isDataChanged = false;
  bool _locked = false;

  void _animateScroll() {
    widget.scrollController!.animateTo(
      widget.scrollController!.position.minScrollExtent + 200,
      duration: const Duration(seconds: 2),
      curve: Curves.fastOutSlowIn,
    );
  }

  _onAnimateEnd() {
    _data.clear();
    _data.addAll(_newData);
    setState(() {});
    _isBoxOpen = !_isBoxOpen;
    _locked = false;
  }

  _animateHandler() {
    _isDataChanged =
        !(_newData.every((e) => _data.contains(e)) && _newData.length == _data.length);

    if (_isDataChanged) {
      if (_newData.isNotEmpty) {
        if (_isBoxOpen) {
          _data.clear();
          _data.addAll(_newData);
          setState(() {});
          _locked = false;
        } else {
          //In here we need to wait animation first
          _height = widget.expandedHeight;
          setState(() {});
        }
      } else {
        _data.clear();
        _height = widget.initialHeight;
        setState(() {});
      }
    } else {
      _locked = false;
    }
  }

  List<Widget> renderColumn(BuildContext context) {
    List<Widget> list = [
      TextField(
        onTap: () {
          if (widget.scrollController != null) {
            _animateScroll();
          }
        },
        style: widget.textInputStyle,
        decoration: widget.inputDecoration ??
            const InputDecoration().applyDefaults(Theme.of(context).inputDecorationTheme),
        onChanged: (String? val) async {
          if (_locked == false) {
            _locked = true;
            if (val != null && val.length >= widget.startLookupLenght) {
              _newData = await widget.onLookup(val);
              await _animateHandler();
            } else {
              _newData = [];
              await _animateHandler();
            }
          }
        },
      ),
    ];

    if (_data.isNotEmpty) {
      List<Widget> childList;
      if (widget.rawItemBuilder != null) {
        childList = _data.map((e) => widget.rawItemBuilder!(context, e)).toList();
      } else {
        childList = _data
            .map((e) => SizedBox(
                  width: widget.resultWidth,
                  child: HorizontalTypeHeadResultWidget<T>(
                      model: e,
                      onSelected: widget.onSelected,
                      smallerResultTitle: widget.smallerResultTitle,
                      imageFit: widget.resultImageBoxFit),
                ))
            .toList();
      }
      list.add(
        SizedBox(
          height: widget.expandedHeight - 64,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            scrollDirection: Axis.horizontal,
            children: childList,
          ),
        ),
      );
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          decoration: widget.containerDecoration ??
              BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(10)),
          duration: const Duration(milliseconds: 250),
          height: _height,
          onEnd: _onAnimateEnd,
          child: Column(children: renderColumn(context)),
        )
      ],
    );
  }
}

class HorizontalTypeHeadResultWidget<T extends HorizontalTypeHeadModel>
    extends StatelessWidget {
  const HorizontalTypeHeadResultWidget(
      {required this.model,
      required this.onSelected,
      required this.smallerResultTitle,
      this.imageFit,
      Key? key})
      : super(key: key);

  final T model;
  final bool smallerResultTitle;
  final void Function(T selected) onSelected;
  final BoxFit? imageFit;

  @override
  Widget build(BuildContext context) {
    //onSelected(model);
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => onSelected(model),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 130,
            child: Stack(
              children: [
                Positioned.fill(
                    child: model.body ??
                        Image.network(model.imageUrl!, fit: imageFit ?? BoxFit.contain)),
                Positioned(
                  bottom: 0,
                  right: 0,
                  width: 120,
                  height: 60,
                  child: Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(180, 0, 0, 0),
                        borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(20.0),
                            topLeft: Radius.circular(20.0)),
                      ),
                      child: Text(
                        model.title,
                        textAlign: TextAlign.center,
                        maxLines: smallerResultTitle ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: smallerResultTitle
                            ? Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(color: Theme.of(context).colorScheme.onPrimary)
                            : Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(color: Theme.of(context).colorScheme.onPrimary),
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HorizontalTypeHeadModel {
  HorizontalTypeHeadModel({required this.title, this.id, this.body, this.imageUrl})
      : assert(body == null || imageUrl == null);

  int? id;
  String title;
  Widget? body;
  String? imageUrl;
}
