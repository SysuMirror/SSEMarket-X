import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sse_market_x/core/api/shop_service.dart';
import 'package:sse_market_x/core/models/product_model.dart';
import 'package:sse_market_x/core/services/blur_effect_service.dart';
import 'package:sse_market_x/views/shop/product_detail_page.dart';
import 'package:sse_market_x/views/shop/create_product_page.dart';
import 'package:sse_market_x/shared/components/loading/skeleton_loader.dart';
import 'package:sse_market_x/shared/components/media/cached_image.dart';
import 'package:sse_market_x/core/services/media_cache_service.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';
import 'package:sse_market_x/core/services/browse_history_service.dart';

/// 闲置物品页面
class ShopPage extends StatefulWidget {
  final Function(int productId)? onProductTap;

  /// 是否作为独立页面展示（从主页全屏进入）
  /// 为 true 时显示返回按钮，且不再为底部导航栏预留高度
  final bool standalone;

  const ShopPage({
    super.key,
    this.onProductTap,
    this.standalone = false,
  });

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final ShopService _shopService = ShopService();
  List<ProductModel> _homeProducts = [];
  List<ProductModel> _historyProducts = [];
  bool _isLoading = true; // 初始化时设置为 true，避免显示空状态
  bool _isRefreshing = false;
  bool _hasLoadedOnce = false;
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();

  /// 点击「搜索」按钮后才生效的关键词（输入过程中不更新结果）
  String _appliedKeyword = '';

  /// 选中的价格筛选索引：0=全部 1=≤20 2=≤50 3=≤100 4=≤500 5=500+
  int _selectedPriceIndex = 0;
  static const List<String> _priceLabels = [
    '全部', '≤20', '≤50', '≤100', '≤500', '500+',
  ];
  static const List<double?> _priceUpperBounds = [
    null, 20, 50, 100, 500, null,
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialProducts();
  }

  Future<void> _loadInitialProducts() async {
    // 尝试从缓存加载
    await _loadCachedProducts();

    // 后台静默刷新
    if (_hasLoadedOnce) {
      _loadProducts(silent: true);
    } else {
      _loadProducts();
    }
  }

  /// 从本地缓存加载商品列表
  Future<void> _loadCachedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final homeJson = prefs.getString('shop_home_products_cache');
      final historyJson = prefs.getString('shop_history_products_cache');

      if (homeJson != null && homeJson.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(homeJson);
        final cachedProducts = jsonList.map((json) => ProductModel.fromDynamic(json)).toList();

        if (mounted) {
          setState(() {
            _homeProducts = cachedProducts;
            _hasLoadedOnce = true;
            _isLoading = false;
          });
        }
      }

      if (historyJson != null && historyJson.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(historyJson);
        final cachedProducts = jsonList.map((json) => ProductModel.fromDynamic(json)).toList();

        if (mounted) {
          setState(() {
            _historyProducts = cachedProducts;
          });
        }
      }

      // 如果没有任何缓存，不设置 _isLoading，让后续的 _loadProducts 正常执行
    } catch (e) {
      debugPrint('加载缓存商品失败: $e');
      // 加载失败，不设置 _isLoading，让后续的 _loadProducts 正常执行
    }
  }

  /// 保存商品列表到本地缓存
  Future<void> _saveCachedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_homeProducts.isNotEmpty) {
        final jsonList = _homeProducts.map((p) => p.toJson()).toList();
        await prefs.setString('shop_home_products_cache', jsonEncode(jsonList));
      }

      if (_historyProducts.isNotEmpty) {
        final jsonList = _historyProducts.map((p) => p.toJson()).toList();
        await prefs.setString('shop_history_products_cache', jsonEncode(jsonList));
      }
    } catch (e) {
      debugPrint('保存缓存商品失败: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final homeProducts = await _shopService.getProducts('home');
      final historyProducts = await _shopService.getProducts('history');

      if (mounted) {
        setState(() {
          _homeProducts = homeProducts;
          _historyProducts = historyProducts;
          _isLoading = false;
          _isRefreshing = false;
          _hasLoadedOnce = true;
        });

        // 保存到缓存（仅在正常加载时）
        if (!silent) {
          _saveCachedProducts();
        }
      }
    } catch (e) {
      debugPrint('加载商品失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadProducts();
  }

  /// 当前是否处于筛选状态（用于区分「无结果」与「暂无商品」提示）
  bool get _hasActiveFilter => _appliedKeyword.isNotEmpty || _selectedPriceIndex > 0;

  /// 搜索关键词与价格筛选同时生效，本地过滤商品列表
  List<ProductModel> _applyFilters(List<ProductModel> products) {
    var result = products;
    final keyword = _appliedKeyword.toLowerCase();
    if (keyword.isNotEmpty) {
      result = result
          .where((p) => p.name.toLowerCase().contains(keyword))
          .toList();
    }
    final upper = _priceUpperBounds[_selectedPriceIndex];
    if (upper != null) {
      result = result.where((p) => p.price <= upper).toList();
    } else if (_selectedPriceIndex == 5) {
      result = result.where((p) => p.price > 500).toList();
    }
    return result;
  }

  /// 仅在点击「搜索」按钮后更新搜索结果
  void _onSearchTap() {
    FocusScope.of(context).unfocus();
    setState(() {
      _appliedKeyword = _searchController.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate top padding for content (StatusBar + AppBar + TabBar)
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 36;
    // Calculate bottom padding for content (NavBar + SafeArea)
    // Note: In IndexPage, bottom nav is overlay, so we need to add its height.
    // Standard bottom nav height is 56? IndexPage uses BottomNavigationBar (default height).
    // Plus safe area bottom.
    // 独立页面模式下底部导航已被覆盖，仅需保留安全区高度。
    final bottomPadding = widget.standalone
        ? MediaQuery.of(context).padding.bottom
        : kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          '闲置物品',
          style: TextStyle(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: IconButton(
              icon: const Icon(Icons.add, color: AppColors.primary),
              tooltip: '发布闲置物品',
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const CreateProductPage(),
                  ),
                );
                if (result == true) {
                  _loadProducts();
                }
              },
            ),
          ),
        ],
        backgroundColor: Colors.transparent, // Important: Transparency for blur
        flexibleSpace: ValueListenableBuilder<bool>(
          valueListenable: BlurEffectService().enabledNotifier,
          builder: (context, isBlurEnabled, _) {
            Widget content = Container(
              decoration: BoxDecoration(
                color: isBlurEnabled
                    ? context.blurBackgroundColor.withOpacity(0.82)
                    : context.surfaceColor,
                border: Border(
                  bottom: BorderSide(
                    color: context.dividerColor.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
              ),
            );

            if (isBlurEnabled) {
              return ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: content,
                ),
              );
            } else {
              return content;
            }
          },
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: widget.standalone
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: context.textPrimaryColor),
                tooltip: '返回',
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: _buildTabs(context, transparent: true), // Pass transparent flag
        ),
      ),
      body: !_hasLoadedOnce && _isLoading && !_isRefreshing
          ? Padding(
              padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
              child: const ProductGridSkeleton(itemCount: 6),
            )
          : PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [
                _buildShopTab(topPadding, bottomPadding),
                _buildMyProductsTab(topPadding, bottomPadding),
              ],
            ),
    );
  }

  Widget _buildTabs(BuildContext context, {bool transparent = false}) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: transparent ? Colors.transparent : context.surfaceColor, // Handle transparency
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildTabButton(context, '商城', 0),
          const SizedBox(width: 24),
          _buildTabButton(context, '我的商品', 1),
        ],
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        _pageController.jumpToPage(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: isSelected ? AppColors.primary : context.textSecondaryColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: isSelected ? 20 : 0,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(1.5),
            ),
            margin: const EdgeInsets.only(bottom: 1),
          ),
        ],
      ),
    );
  }

  /// 「商城」分页：搜索栏 + 价格筛选 + 纵向商品列表
  Widget _buildShopTab(double topPadding, double bottomPadding) {
    final filtered = _applyFilters(_homeProducts);
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        children: [
          _buildSearchBar(),
          _buildPriceFilter(),
          Expanded(
            child: filtered.isEmpty
                ? _wrapRefresh(
                    _buildEmptyState(
                      title: _hasActiveFilter ? '没有符合条件的商品' : '暂无商品',
                      subtitle: _hasActiveFilter
                          ? '请调整搜索关键词或价格筛选'
                          : '下拉刷新或稍后再来看看',
                      icon: _hasActiveFilter
                          ? Icons.search_off
                          : Icons.inventory_2_outlined,
                    ),
                  )
                : _buildProductList(filtered, bottomPadding),
          ),
        ],
      ),
    );
  }

  /// 「我的商品」分页：纵向商品列表
  Widget _buildMyProductsTab(double topPadding, double bottomPadding) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: _historyProducts.isEmpty
          ? _wrapRefresh(
              _buildEmptyState(
                title: '暂无我的商品',
                subtitle: '点击右上角 + 发布你的闲置物品',
                icon: Icons.inventory_2_outlined,
              ),
            )
          : _buildProductList(_historyProducts, bottomPadding),
    );
  }

  /// 搜索栏 + 「搜索」按钮（结果仅在点击按钮后更新）
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: context.backgroundColor,
                borderRadius: BorderRadius.circular(19),
              ),
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.textPrimaryColor,
                ),
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  hintText: '搜索商品名称',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: context.textTertiaryColor,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: context.textTertiaryColor,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _onSearchTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(48, 38),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '搜索',
              style: TextStyle(fontSize: 14, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// 价格筛选条：选中项为主题蓝，未选中为浅灰
  Widget _buildPriceFilter() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        itemCount: _priceLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedPriceIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPriceIndex = index;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : context.backgroundColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                _priceLabels[index],
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.white : context.textSecondaryColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 纵向商品列表
  Widget _buildProductList(List<ProductModel> products, double bottomPadding) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding + 16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildProductItem(products[index]);
        },
      ),
    );
  }

  /// 单个商品卡片：图片 + 名称 + 价格，已售时图片上叠加灰色「已售」标签
  Widget _buildProductItem(ProductModel product) {
    return GestureDetector(
      onTap: () => _openProduct(product),
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: product.firstPhoto.isNotEmpty
                        ? CachedImage(
                            imageUrl: product.firstPhoto,
                            fit: BoxFit.cover,
                            category: CacheCategory.product,
                            decodeWidth: 96, // 与显示宽度一致，按像素比解码
                            errorWidget: Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 32,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          )
                        : Container(
                            color: context.backgroundColor,
                            child: Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 32,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ),
                  ),
                ),
                if (product.isSold)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.75),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '已售',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 96,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 15,
                        color: context.textPrimaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '¥${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 空状态（支持下拉刷新）
  Widget _wrapRefresh(Widget child) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: context.textTertiaryColor),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: context.textTertiaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openProduct(ProductModel product) async {
    // 添加到浏览历史（在点击时记录）
    await BrowseHistoryService().addProductHistory(product.id, product);

    if (!mounted) return;
    if (widget.onProductTap != null) {
      widget.onProductTap!(product.id);
    } else {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ProductDetailPage(
            productId: product.id,
          ),
        ),
      );
      // 如果商品被删除或标记售出，刷新列表
      if (result == true && mounted) {
        _loadProducts();
      }
    }
  }
}
