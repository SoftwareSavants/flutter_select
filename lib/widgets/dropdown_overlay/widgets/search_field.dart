part of '../../../custom_dropdown.dart';

class _SearchField<T> extends StatefulWidget {
  final List<T> items;
  final ValueChanged<List<T>> onSearchedItems;
  final String searchHintText;
  final _SearchType? searchType;
  final Future<List<T>> Function(String)? futureRequest;
  final Duration? futureRequestDelay;
  final ValueChanged<bool>? onFutureRequestLoading, mayFoundResult;
  final SearchFieldDecoration? decoration;
  final FocusNode? focusNode;

  const _SearchField.forListData({
    super.key,
    required this.items,
    required this.onSearchedItems,
    required this.searchHintText,
    required this.decoration,
    this.focusNode,
  })  : searchType = _SearchType.onListData,
        futureRequest = null,
        futureRequestDelay = null,
        onFutureRequestLoading = null,
        mayFoundResult = null;

  const _SearchField.forRequestData({
    super.key,
    required this.items,
    required this.onSearchedItems,
    required this.searchHintText,
    required this.futureRequest,
    required this.futureRequestDelay,
    required this.onFutureRequestLoading,
    required this.mayFoundResult,
    required this.decoration,
    required this.focusNode,
  }) : searchType = _SearchType.onRequestData;

  @override
  State<_SearchField<T>> createState() => _SearchFieldState<T>();
}

class _SearchFieldState<T> extends State<_SearchField<T>> {
  final searchCtrl = TextEditingController();
  bool isFieldEmpty = false;
  late FocusNode focusNode = widget.focusNode ?? FocusNode();
  Timer? _delayTimer;

  double? lastOffsetBeforeFocus;

  @override
  void initState() {
    super.initState();

    focusNode.addListener(() async {
      final scrollController = PrimaryScrollController.maybeOf(context);

      if (scrollController == null) return;

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        if (focusNode.hasFocus) {
          lastOffsetBeforeFocus = scrollController.offset;
          scrollController.animateTo(
            scrollController.offset +
                EdgeInsets.fromViewPadding(View.of(context).viewInsets,
                            View.of(context).devicePixelRatio)
                        .bottom *
                    1.5,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else if (lastOffsetBeforeFocus != null) {
          scrollController.animateTo(
            lastOffsetBeforeFocus!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          lastOffsetBeforeFocus = null;
        }
      }
    });

    if (widget.searchType == _SearchType.onRequestData &&
        widget.items.isEmpty) {
      focusNode.requestFocus();
    }

    if (widget.items.isEmpty) searchRequest('');
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    _delayTimer?.cancel();
    super.dispose();
  }

  void onSearch(String query) {
    final result = widget.items.where(
      (item) {
        if (item is CustomDropdownListFilter) {
          return item.filter(query);
        } else {
          return item.toString().toLowerCase().contains(query.toLowerCase());
        }
      },
    ).toList();
    widget.onSearchedItems(result);
  }

  void onClear() {
    if (searchCtrl.text.isNotEmpty) {
      searchCtrl.clear();
      if (widget.searchType == _SearchType.onRequestData) {
        _onFutureRequestSearch('');
      } else {
        widget.onSearchedItems(widget.items);
      }
    }
  }

  void searchRequest(String val) async {
    List<T> result = [];
    try {
      result = await widget.futureRequest!(val);
      widget.onFutureRequestLoading!(false);
    } catch (_) {
      widget.onFutureRequestLoading!(false);
    }
    widget.onSearchedItems(result);
    widget.mayFoundResult!(result.isNotEmpty);

    if (isFieldEmpty) {
      isFieldEmpty = false;
    }
  }

  void _onFutureRequestSearch(String val) {
    widget.onFutureRequestLoading!(true);

    if (widget.futureRequestDelay != null) {
      _delayTimer?.cancel();
      _delayTimer = Timer(widget.futureRequestDelay ?? Duration.zero, () {
        searchRequest(val);
      });
    } else {
      searchRequest(val);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        focusNode: focusNode,
        style: widget.decoration?.textStyle,
        onChanged: (val) async {
          if (val.isEmpty) {
            isFieldEmpty = true;
          } else if (isFieldEmpty) {
            isFieldEmpty = false;
          }

          if (widget.searchType != null &&
              widget.searchType == _SearchType.onRequestData) {
            _onFutureRequestSearch(val);
          } else if (widget.searchType == _SearchType.onListData) {
            onSearch(val);
          } else {
            widget.onSearchedItems(widget.items);
          }
        },
        controller: searchCtrl,
        decoration: InputDecoration(
          filled: true,
          fillColor: widget.decoration?.fillColor ??
              SearchFieldDecoration._defaultFillColor,
          constraints: widget.decoration?.constraints ??
              const BoxConstraints.tightFor(height: 40),
          contentPadding:
              widget.decoration?.contentPadding ?? const EdgeInsets.all(8),
          hintText: widget.searchHintText,
          hintStyle: widget.decoration?.hintStyle,
          prefixIcon: widget.decoration?.prefixIcon ??
              const Icon(Icons.search, size: 22),
          suffixIcon: widget.decoration?.suffixIcon?.call(onClear) ??
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 20),
              ),
          border: widget.decoration?.border ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(.25),
                  width: 1,
                ),
              ),
          enabledBorder: widget.decoration?.border ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(.25),
                  width: 1,
                ),
              ),
          focusedBorder: widget.decoration?.focusedBorder ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(.25),
                  width: 1,
                ),
              ),
        ),
      ),
    );
  }
}
