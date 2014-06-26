module Tgios
  class UICollectionViewBinding < BindingBase
    include PlasticCup

    def initialize(*args)
      super
      @events={}
      @events[:setup_cell]=->(cell, subview, index_path) { setup_cell(cell, subview, index_path) }
    end

    def on(event_name, &block)
      @events[event_name]=block.weak!
      self
    end

    def bind(collection_view, views=nil)
      @collection_view = WeakRef.new(collection_view)
      @collection_view.registerClass(UICollectionViewCell, forCellWithReuseIdentifier:'UICollectionViewCell')
      @views = WeakRef.new(views) unless views.nil?
      @collection_view.delegate = self
      @collection_view.dataSource = self
      self
    end

    def reload(views=nil)
      @views = WeakRef.new(views) unless views.nil?
      @collection_view.reloadData if @collection_view.weakref_alive?
    end

    def collectionView(collectionView, numberOfItemsInSection: section)
      @views.count
    end

    def collectionView(collectionView, cellForItemAtIndexPath: indexPath)
      cell = collectionView.dequeueReusableCellWithReuseIdentifier('UICollectionViewCell', forIndexPath:indexPath)
      @events[:setup_cell].call(cell, view_at(indexPath), indexPath)
      cell
    end

    def collectionView(collectionView, didSelectItemAtIndexPath: indexPath)
      @events[:item_tapped].call(view_at(indexPath), indexPath.row) unless @events[:item_tapped].nil?
    end

    def scrollViewDidEndDecelerating(scrollView)
      page = (scrollView.contentOffset.x / scrollView.frame.size.width).round
      if page != @page
        @page = page
        @events[:page_changed].call(page) unless @events[:page_changed].nil?
      end
    end

    def view_at(index_path)
      @views[index_path.row]
    end

    def setup_cell(cell, subview, index_path)
      cell.contentView.subviews.makeObjectsPerformSelector('removeFromSuperview')
      cell.contentView.addSubview(subview)
    end

    def self.new_horizontal_collection_view(options={})
      layout = Base.style(UICollectionViewFlowLayout.new,
                          {scrollDirection: UICollectionViewScrollDirectionHorizontal,
                           sectionInset:UIEdgeInsetsMake(0, 15, 0, 10)}.merge(options[:layout] || {}))
      Base.style(UICollectionView.alloc.initWithFrame(CGRectZero, collectionViewLayout: layout),
                 {backgroundColor: :white.uicolor}.merge(options[:view] || {})
      )
    end

    def onPrepareForRelease
      @events=nil
      @collection_view.delegate = nil
      @collection_view.dataSource = nil
      @collection_view = nil
      @views = nil
    end
  end
end