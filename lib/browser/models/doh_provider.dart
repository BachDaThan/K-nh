/// DNS-over-HTTPS provider preset + custom.
/// Gần với màn "DNS bảo mật" Android (Private DNS), nhưng là **DoH trong app**.
class DohProvider {
  final String id;
  final String name;
  final String url;
  final String? subtitle;
  final bool isCustom;

  const DohProvider({
    required this.id,
    required this.name,
    required this.url,
    this.subtitle,
    this.isCustom = false,
  });

  static const List<DohProvider> presets = [
    DohProvider(
      id: 'cloudflare',
      name: 'Cloudflare (1.1.1.1)',
      url: 'https://cloudflare-dns.com/dns-query',
      subtitle: 'Nhanh · privacy-oriented',
    ),
    DohProvider(
      id: 'google',
      name: 'Google (Public DNS)',
      url: 'https://dns.google/dns-query',
      subtitle: '8.8.8.8 · phổ biến',
    ),
    DohProvider(
      id: 'opendns',
      name: 'OpenDNS',
      url: 'https://doh.opendns.com/dns-query',
      subtitle: 'Cisco OpenDNS',
    ),
    DohProvider(
      id: 'cleanbrowsing_family',
      name: 'CleanBrowsing (Family Filter)',
      url: 'https://doh.cleanbrowsing.org/doh/family-filter/',
      subtitle: 'Lọc nội dung family',
    ),
    DohProvider(
      id: 'adguard',
      name: 'AdGuard DNS',
      url: 'https://dns.adguard-dns.com/dns-query',
      subtitle: 'Chặn quảng cáo/tracker (DNS)',
    ),
    DohProvider(
      id: 'cloudflare_family',
      name: 'Cloudflare Family',
      url: 'https://family.cloudflare-dns.com/dns-query',
      subtitle: 'Malware + adult content filter',
    ),
  ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'subtitle': subtitle,
        'isCustom': isCustom,
      };

  factory DohProvider.fromJson(Map<String, dynamic> json) => DohProvider(
        id: json['id'] as String,
        name: json['name'] as String,
        url: json['url'] as String,
        subtitle: json['subtitle'] as String?,
        isCustom: json['isCustom'] as bool? ?? false,
      );
}
