import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() => runApp(const ElxvroScanApp());

class ElxvroScanApp extends StatelessWidget {
  const ElxvroScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ELXVRO Scan',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF8B5CF6),
        scaffoldBackgroundColor: const Color(0xFF090A0F),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF151720),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const ScanDesignerPage(),
    );
  }
}

enum CardTier { free, pro }

class CardTemplate {
  final int id;
  final CardTier tier;
  final String sector;
  final String asset;
  final int layout;
  final double shade;

  const CardTemplate({
    required this.id,
    required this.tier,
    required this.sector,
    required this.asset,
    required this.layout,
    required this.shade,
  });
}

class SectorAsset {
  final String name;
  final String asset;
  const SectorAsset(this.name, this.asset);
}

const sectors = <SectorAsset>[
  SectorAsset('Berber', 'assets/backgrounds/barber.jpg'),
  SectorAsset('Kafe', 'assets/backgrounds/cafe.jpg'),
  SectorAsset('Restoran', 'assets/backgrounds/restaurant.jpg'),
  SectorAsset('Pastane', 'assets/backgrounds/bakery.jpg'),
  SectorAsset('Spa', 'assets/backgrounds/spa.jpg'),
  SectorAsset('Butik', 'assets/backgrounds/boutique.jpg'),
  SectorAsset('Spor Salonu', 'assets/backgrounds/gym.jpg'),
  SectorAsset('Klinik', 'assets/backgrounds/clinic.jpg'),
  SectorAsset('Emlak', 'assets/backgrounds/realestate.jpg'),
  SectorAsset('Otomotiv', 'assets/backgrounds/automotive.jpg'),
];

List<CardTemplate> buildTemplates(CardTier tier) {
  final out = <CardTemplate>[];
  for (var sectorIndex = 0; sectorIndex < sectors.length; sectorIndex++) {
    for (var variant = 0; variant < 5; variant++) {
      out.add(CardTemplate(
        id: (tier == CardTier.free ? 1 : 51) + (sectorIndex * 5) + variant,
        tier: tier,
        sector: sectors[sectorIndex].name,
        asset: sectors[sectorIndex].asset,
        layout: tier == CardTier.free ? variant : variant + 5,
        shade: tier == CardTier.free
            ? 0.34 + (variant * 0.045)
            : 0.20 + (variant * 0.035),
      ));
    }
  }
  return out;
}

class ScanDesignerPage extends StatefulWidget {
  const ScanDesignerPage({super.key});

  @override
  State<ScanDesignerPage> createState() => _ScanDesignerPageState();
}

class _ScanDesignerPageState extends State<ScanDesignerPage> {
  final brandCtrl = TextEditingController(text: 'ELXVRO');
  final subtitleCtrl = TextEditingController(text: 'Bizi keşfedin');
  final qrCtrl = TextEditingController(text: 'https://elxvro.com');

  late final List<CardTemplate> freeTemplates = buildTemplates(CardTier.free);
  late final List<CardTemplate> proTemplates = buildTemplates(CardTier.pro);

  CardTier tier = CardTier.free;
  late CardTemplate selected = freeTemplates.first;

  @override
  void initState() {
    super.initState();
    brandCtrl.addListener(_refresh);
    subtitleCtrl.addListener(_refresh);
    qrCtrl.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    brandCtrl.dispose();
    subtitleCtrl.dispose();
    qrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = tier == CardTier.free ? freeTemplates : proTemplates;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ELXVRO Scan'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'v4.1 TEST',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 840) {
              return Row(
                children: [
                  SizedBox(width: 390, child: _controls(templates)),
                  const VerticalDivider(width: 1),
                  Expanded(child: _previewArea()),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                _previewCard(),
                const SizedBox(height: 18),
                _fields(),
                const SizedBox(height: 18),
                _tierSelector(),
                const SizedBox(height: 14),
                _templateGrid(templates),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _controls(List<CardTemplate> templates) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _fields(),
        const SizedBox(height: 18),
        _tierSelector(),
        const SizedBox(height: 14),
        _templateGrid(templates),
      ],
    );
  }

  Widget _previewArea() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: _previewCard(),
        ),
      ),
    );
  }

  Widget _fields() {
    return Column(
      children: [
        TextField(
          controller: brandCtrl,
          decoration: const InputDecoration(
            labelText: 'İşletme / marka adı',
            prefixIcon: Icon(Icons.storefront_outlined),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: subtitleCtrl,
          decoration: const InputDecoration(
            labelText: 'Kısa mesaj',
            prefixIcon: Icon(Icons.short_text_rounded),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: qrCtrl,
          decoration: const InputDecoration(
            labelText: 'QR içeriği / bağlantı',
            prefixIcon: Icon(Icons.qr_code_2_rounded),
          ),
        ),
      ],
    );
  }

  Widget _tierSelector() {
    return SegmentedButton<CardTier>(
      segments: const [
        ButtonSegment(
          value: CardTier.free,
          icon: Icon(Icons.bolt_outlined),
          label: Text('FREE 50'),
        ),
        ButtonSegment(
          value: CardTier.pro,
          icon: Icon(Icons.workspace_premium_outlined),
          label: Text('PRO 50'),
        ),
      ],
      selected: {tier},
      onSelectionChanged: (value) {
        setState(() {
          tier = value.first;
          selected = tier == CardTier.free
              ? freeTemplates.first
              : proTemplates.first;
        });
      },
    );
  }

  Widget _templateGrid(List<CardTemplate> templates) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: templates.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.70,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final item = templates[index];
        final active = selected.id == item.id;
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => selected = item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white12,
                width: active ? 2.2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(item.asset, fit: BoxFit.cover),
                Container(color: Colors.black.withValues(alpha: 0.34)),
                Positioned(
                  left: 7,
                  top: 7,
                  child: _badge(
                    item.tier == CardTier.pro ? 'PRO' : 'FREE',
                    item.tier == CardTier.pro
                        ? const Color(0xFFF5B942)
                        : const Color(0xFF59D6A2),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#' + item.id.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        item.sector,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _previewCard() {
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(selected.asset, fit: BoxFit.cover),
            Container(color: Colors.black.withValues(alpha: selected.shade)),
            _dynamicOverlay(),
            Positioned(
              left: 16,
              top: 16,
              child: _badge(
                selected.tier == CardTier.pro ? 'PRO' : 'FREE',
                selected.tier == CardTier.pro
                    ? const Color(0xFFF5B942)
                    : const Color(0xFF59D6A2),
              ),
            ),
            Positioned(
              right: 16,
              top: 16,
              child: _badge(
                selected.sector,
                Colors.white.withValues(alpha: 0.18),
              ),
            ),
            _composition(),
          ],
        ),
      ),
    );
  }

  Widget _dynamicOverlay() {
    final alignment = switch (selected.layout % 5) {
      0 => Alignment.bottomCenter,
      1 => Alignment.topCenter,
      2 => Alignment.centerLeft,
      3 => Alignment.centerRight,
      _ => Alignment.bottomCenter,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: alignment,
          end: Alignment.center,
          colors: [
            Colors.black.withValues(
              alpha: selected.tier == CardTier.pro ? 0.78 : 0.66,
            ),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _composition() {
    final content = _contentBlock();
    switch (selected.layout) {
      case 0:
      case 5:
        return Positioned(left: 22, right: 22, bottom: 24, child: content);
      case 1:
      case 6:
        return Positioned(left: 22, right: 22, top: 72, child: content);
      case 2:
      case 7:
        return Positioned(left: 22, bottom: 24, width: 230, child: content);
      case 3:
      case 8:
        return Positioned(right: 22, bottom: 24, width: 230, child: content);
      default:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: content,
          ),
        );
    }
  }

  Widget _contentBlock() {
    final pro = selected.tier == CardTier.pro;
    final title = brandCtrl.text.trim().isEmpty ? 'ELXVRO' : brandCtrl.text.trim();
    final subtitle = subtitleCtrl.text.trim().isEmpty
        ? 'Bizi keşfedin'
        : subtitleCtrl.text.trim();
    final qrData = qrCtrl.text.trim().isEmpty
        ? 'https://elxvro.com'
        : qrCtrl.text.trim();

    return Container(
      padding: EdgeInsets.all(pro ? 18 : 14),
      decoration: BoxDecoration(
        color: pro
            ? const Color(0xFF11131A).withValues(alpha: 0.78)
            : Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(pro ? 24 : 18),
        border: Border.all(
          color: pro
              ? const Color(0xFFF5B942).withValues(alpha: 0.70)
              : Colors.white.withValues(alpha: 0.18),
        ),
        boxShadow: pro
            ? [
                BoxShadow(
                  blurRadius: 26,
                  color: Colors.black.withValues(alpha: 0.32),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: pro ? 26 : 23,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: pro ? 150 : 136,
            height: pro ? 150 : 136,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(pro ? 22 : 16),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              padding: EdgeInsets.zero,
              eyeStyle: QrEyeStyle(
                eyeShape: pro ? QrEyeShape.circle : QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape:
                    pro ? QrDataModuleShape.circle : QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'TARA',
            style: TextStyle(
              fontSize: pro ? 16 : 14,
              fontWeight: FontWeight.w900,
              letterSpacing: pro ? 5.0 : 3.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '#' +
                selected.id.toString().padLeft(2, '0') +
                ' • ' +
                selected.sector,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.66),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
