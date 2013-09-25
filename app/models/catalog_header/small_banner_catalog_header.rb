class CatalogHeader::SmallBannerCatalogHeader < CatalogHeader::CatalogHeader
  attr_accessible :medium_banner, :link_medium_banner,:alt_medium_banner,
                  :small_banner1, :link_small_banner1,:alt_small_banner1,
                  :small_banner2, :link_small_banner2,:alt_small_banner2

  mount_uploader :medium_banner, CatalogHeaderUploader
  mount_uploader :small_banner1, CatalogHeaderUploader
  mount_uploader :small_banner2, CatalogHeaderUploader
end
