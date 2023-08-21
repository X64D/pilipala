import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:get/get.dart';
import 'package:pilipala/common/widgets/http_error.dart';
import 'controller.dart';
import 'widgets/hot_keyword.dart';
import 'widgets/search_text.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
  static final RouteObserver<PageRoute> routeObserver =
      RouteObserver<PageRoute>();
}

class _SearchPageState extends State<SearchPage> with RouteAware {
  final SSearchController _searchController = Get.put(SSearchController());
  late Future? _futureBuilderFuture;

  @override
  void initState() {
    super.initState();
    _futureBuilderFuture = _searchController.queryHotSearchList();
  }

  @override
  // 返回当前页面时
  void didPopNext() async {
    _searchController.searchFocusNode.requestFocus();
    super.didPopNext();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SearchPage.routeObserver
        .subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      closedElevation: 0,
      openElevation: 0,
      onClosed: (_) {
        // 在 openBuilder 关闭时触发的回调函数
        _searchController.onClear();
      },
      openColor: Theme.of(context).colorScheme.background,
      middleColor: Theme.of(context).colorScheme.background,
      closedColor: Theme.of(context).colorScheme.background,
      closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30.0))),
      openShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30.0))),
      closedBuilder: (BuildContext context, VoidCallback openContainer) {
        return Container(
          width: 250,
          height: 44,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(25)),
          ),
          child: Material(
            color:
                Theme.of(context).colorScheme.secondaryContainer.withAlpha(115),
            child: InkWell(
              splashColor: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              onTap: openContainer,
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    Icons.search_outlined,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Obx(
                      () => Text(
                        _searchController.defaultSearch.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      openBuilder: (BuildContext context, VoidCallback _) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            shape: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.08),
                width: 1,
              ),
            ),
            titleSpacing: 0,
            actions: [
              Hero(
                tag: 'searchTag',
                child: IconButton(
                    onPressed: () => _searchController.submit(),
                    icon: const Icon(CupertinoIcons.search, size: 22)),
              ),
              const SizedBox(width: 10)
            ],
            title: Obx(
              () => TextField(
                autofocus: true,
                focusNode: _searchController.searchFocusNode,
                controller: _searchController.controller.value,
                textInputAction: TextInputAction.search,
                onChanged: (value) => _searchController.onChange(value),
                decoration: InputDecoration(
                  hintText: _searchController.hintText,
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 22,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    onPressed: () => _searchController.onClear(),
                  ),
                ),
                onSubmitted: (String value) => _searchController.submit(),
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 12),
                // 搜索建议
                _searchSuggest(),
                // 热搜
                hotSearch(),
                // 搜索历史
                _history()
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _searchSuggest() {
    return Obx(
      () => _searchController.searchSuggestList.isNotEmpty &&
              _searchController.searchSuggestList.first.term != null
          ? ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _searchController.searchSuggestList.length,
              itemBuilder: (context, index) {
                return InkWell(
                  customBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onTap: () => _searchController.onClickKeyword(
                      _searchController.searchSuggestList[index].term!),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, top: 9, bottom: 9),
                    // child: Text(
                    //   _searchController.searchSuggestList[index].term!,
                    // ),
                    child: _searchController.searchSuggestList[index].textRich,
                  ),
                );
              },
            )
          : const SizedBox(),
    );
  }

  Widget hotSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 14, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 0, 6),
            child: Text(
              '大家都在搜',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          LayoutBuilder(
            builder: (context, boxConstraints) {
              final double width = boxConstraints.maxWidth;
              return FutureBuilder(
                future: _futureBuilderFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    Map data = snapshot.data as Map;
                    if (data['status']) {
                      return HotKeyword(
                        width: width,
                        hotSearchList: _searchController.hotSearchList,
                        onClick: (keyword) async {
                          _searchController.searchFocusNode.unfocus();
                          await Future.delayed(
                              const Duration(milliseconds: 150));
                          _searchController.onClickKeyword(keyword);
                        },
                      );
                    } else {
                      return HttpError(
                        errMsg: data['msg'],
                        fn: () => setState(() {}),
                      );
                    }
                  } else {
                    // 缓存数据
                    if (_searchController.hotSearchList.isNotEmpty) {
                      return HotKeyword(
                        width: width,
                        hotSearchList: _searchController.hotSearchList,
                      );
                    } else {
                      return const SizedBox();
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _history() {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 25, 6, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_searchController.historyList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 0, 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '搜索历史',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => _searchController.onClearHis(),
                      child: const Text('清空'),
                    )
                  ],
                ),
              ),
            // if (_searchController.historyList.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              direction: Axis.horizontal,
              textDirection: TextDirection.ltr,
              children: [
                for (int i = 0; i < _searchController.historyList.length; i++)
                  SearchText(
                    searchText: _searchController.historyList[i],
                    searchTextIdx: i,
                    onSelect: (value) => _searchController.onSelect(value),
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
