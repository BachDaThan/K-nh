/// DNS-over-HTTPS provider preset + custom.
class DohProvider {
  final String id;
  final String name;
  final String url; // DoH endpoint, e.g. https://cloudflare-dns.com/dns-query
  final bool isCustom;

  const DohProvider({
    required this.id,
    required this.name,
    required this.url,
    this.isCustom = false,
  });

  static const List<DohProvider> presets = [
    DohProvider(
      id: 'cloudflare',
      name: 'Cloudflare (1.1.1.1)',
      url: 'https://cloudflare-dns.com/dns-query',
    ),
    DohProvider(
      id: 'adguard',
      name: 'AdGuard DNS',
      url: 'https://dns.adguard-dns.com/dns-query',
    ),
    DohProvider(
      id: 'google',
      name: 'Google (8.8.8.8)',
      url: 'https://dns.google/dns-query',
    ),
    DohProvider(
      id: 'cloudflare_family',
      name: 'Cloudflare Family',
      url: 'https://family.cloudflare-dns.com/dns-query',
    ),
  ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'isCustom': isCustom,
      };

  factory DohProvider.fromJson(Map<String, dynamic> json) => DohProvider(
        id: json['id'] as String,
        name: json['name'] as String,
        url: json['url'] as String,
        isCustom: json['isCustom'] as bool? ?? false,
      );
}
