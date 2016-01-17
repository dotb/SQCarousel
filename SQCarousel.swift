/*
Copyright (C) 2009 Bradley Clayton. All rights reserved.

SQCarousel can be downloaded from:
https://github.com/dotb/SQCarousel

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

* Neither the name of the author nor the names of its contributors may be used
to endorse or promote products derived from this software without specific
prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import UIKit

public protocol SQCarouselDataSource : NSObjectProtocol
{
    func carousel(carousel: SQCarousel, cellForRowAtIndex index: Int) -> UIViewController
    func numberOfCellsInCarousel(carousel: SQCarousel) -> Int
    func cellSizeForCarousel(carousel: SQCarousel) -> CGSize
    func paddingSizeForCarousel(carousel: SQCarousel) -> CGFloat
    func cacheSizeForCarousel(carousel: SQCarousel) -> Int
    func carousel(carousel: SQCarousel, didScrollToIndex index: Int)
}

public class SQCarousel: UIScrollView, UIScrollViewDelegate
{
    public var currentIndex: Int = 0
    public var snapToPage = false
    public var viewControllers: [UIViewController] = []
    public weak var dataSource: SQCarouselDataSource?
    public weak var scrollviewDelegate: UIScrollViewDelegate?
    public weak override var delegate: UIScrollViewDelegate?
    {
        set
        {
            // Override the
            scrollviewDelegate = delegate
        }
        get
        {
            return scrollviewDelegate
        }
    }

    // MARK: Object methods
    override init(frame: CGRect)
    {
        super.init(frame: frame)

        // Set up the scroll view
        self.delegate = self
        self.decelerationRate = UIScrollViewDecelerationRateFast
        self.canCancelContentTouches = true
    }

    public required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    // MARK: UIView methods
    public override func layoutSubviews()
    {
        super.layoutSubviews()
        
        if let dataSource = dataSource
        {
            let numberOfColumns = dataSource.numberOfCellsInCarousel(self)
            let viewSize = dataSource.cellSizeForCarousel(self)
            let padding = dataSource.paddingSizeForCarousel(self)
            let cacheSize = dataSource.cacheSizeForCarousel(self)
            let contentOffset = self.contentOffset
            var startIndex = Int(contentOffset.x / (viewSize.width + padding)) - cacheSize / 2
            var viewsToLoad = (Int(contentOffset.x + self.bounds.size.width) / (Int(viewSize.width) + Int(padding))) + cacheSize / 2
            
            startIndex = (startIndex < 0) ? 0 : startIndex
            viewsToLoad = (viewsToLoad > numberOfColumns) ? numberOfColumns : viewsToLoad
            
            // Adjust the content size
            self.contentSize = CGSizeMake(CGFloat(numberOfColumns * (Int(padding) + Int(viewSize.width)) + Int(padding)), self.bounds.size.height)
                        
            // Fetch and place the view objects
            for var i = startIndex; i < viewsToLoad; i++
            {
                var viewControllerToPlace: UIViewController?
                if (i < viewControllers.count)
                {
                    viewControllerToPlace = viewControllers[i]
                }
                else
                {
                    let newViewController = dataSource.carousel(self, cellForRowAtIndex: i)
                    viewControllers.insert(newViewController, atIndex: i)
                    viewControllerToPlace = newViewController
                }
                

                if let viewControllerToPlace = viewControllerToPlace
                {
                    if nil == viewControllerToPlace.view.superview
                    {
                        var viewFrame = viewControllerToPlace.view.frame
                        viewFrame.size = viewSize
                        viewFrame.origin.y = (self.frame.size.height / 2) - (viewFrame.size.height / 2);
                        viewFrame.origin.x = padding + CGFloat(i) * (padding + viewSize.width);
                        viewControllerToPlace.view.frame = viewFrame
                        
                        viewControllerToPlace.viewWillAppear(false)
                        self.addSubview(viewControllerToPlace.view)
                        viewControllerToPlace.viewDidAppear(false)
                    }
                }
            }
            
            // Remove unseen view objects
            for var i = 0; i < startIndex; i++
            {
                if (i < viewControllers.count)
                {
                    let viewControllerToRemove = viewControllers[i]
                    viewControllerToRemove.viewWillDisappear(false)
                    viewControllerToRemove.view.removeFromSuperview()
                    viewControllerToRemove.viewDidDisappear(false)
                }
            }
            for var i = viewsToLoad + 1; i < numberOfColumns; i++
            {
                if (i < viewControllers.count)
                {
                    let viewControllerToRemove = viewControllers[i]
                    viewControllerToRemove.viewWillDisappear(false)
                    viewControllerToRemove.view.removeFromSuperview()
                    viewControllerToRemove.viewDidDisappear(false)
                }	
            }
            
        }
    } // LayoutSubviews
    
    // MARK: UIScrollViewDelegate methods
    public func scrollViewDidScroll(scrollView: UIScrollView)
    {
        if let dataSource = dataSource
        {
            let viewSize = dataSource.cellSizeForCarousel(self)
            let padding = dataSource.paddingSizeForCarousel(self)
            let contentOffset = self.contentOffset
        
            let index = (contentOffset.x + padding + viewSize.width / 2) / (padding * 2 + viewSize.width)
        
            if (Int(index) != currentIndex)
            {
                currentIndex = Int(contentOffset.x + padding + viewSize.width / 2)
                currentIndex = currentIndex / Int(padding * 2 + viewSize.width)
                currentIndex = (currentIndex < 0) ? 0 : currentIndex
        
            
                if let viewControllerForDisplay = viewControllerOnDisplay()
                {
                    viewControllerForDisplay.viewWillAppear(true)
                }
            
                dataSource.carousel(self, didScrollToIndex: currentIndex)
                
                if let viewControllerForDisplay = viewControllerOnDisplay()
                {
                    viewControllerForDisplay.viewDidAppear(true)
                }
            }
        } // if dataSource
        
        self.setNeedsLayout()
        
        if let scrollviewDelegate = scrollviewDelegate
        {
            if let scrollViewDidScroll = scrollviewDelegate.scrollViewDidScroll
            {
                scrollViewDidScroll(scrollView)
                    
            }
        }
    }
    
    
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
    {
        if let dataSource = dataSource
        {
            if (snapToPage)
            {
                let viewSize = dataSource.cellSizeForCarousel(self)
                let padding = dataSource.paddingSizeForCarousel(self)

                targetContentOffset.memory.x = (CGFloat(currentIndex) * (padding + viewSize.width))
                targetContentOffset.memory.x -= ((self.frame.size.width - viewSize.width) / 2) + padding
    
                // Fix an issue where an x value of 0 does not move the scrollview
                if (targetContentOffset.memory.x <= 0)
                {
                    targetContentOffset.memory.x = 1;
                }
            }
        }
        
        if let scrollviewDelegate = scrollviewDelegate
        {
            if let scrollViewWillEndDragging = scrollviewDelegate.scrollViewWillEndDragging
            {
                scrollViewWillEndDragging(self, withVelocity: velocity, targetContentOffset: targetContentOffset)
            }
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView)
    {
        if let scrollviewDelegate = scrollviewDelegate
        {
            if let scrollViewDidEndScrollingAnimation = scrollviewDelegate.scrollViewDidEndScrollingAnimation
            {
                scrollViewDidEndScrollingAnimation(scrollView)
            }
        }
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView)
    {
        if let scrollviewDelegate = scrollviewDelegate
        {
            if let scrollViewDidEndDecelerating = scrollviewDelegate.scrollViewDidEndDecelerating
            {
                scrollViewDidEndDecelerating(scrollView)
            }
        }
    }

    // MARK: Public methods
    public func reloadData()
    {
        self.removeAllSubviews()
        viewControllers.removeAll()
        self.setNeedsLayout()
    }
    
    public func reloadDataAfterIndex(index: Int)
    {
        self.removeAllSubviews()

        for var i = index; i < viewControllers.count; i++
        {
            viewControllers.removeAtIndex(i)
        }
        self.setNeedsLayout()
    }
    
    public func scrollToIndex(index: Int, animated: Bool)
    {
        if let dataSource = dataSource
        {
            if (index >= 0)
            {
                let viewSize = dataSource.cellSizeForCarousel(self)
                let padding = dataSource.paddingSizeForCarousel(self)
    
                var scrollX = (CGFloat(index) * (padding + viewSize.width))
                scrollX -= ((self.frame.size.width - viewSize.width) / 2) + padding
                let scrollRect = CGRectMake(scrollX, 0, self.bounds.size.width, self.bounds.size.height)
                self.scrollRectToVisible(scrollRect, animated: animated)
            }
        }
    }
    
    public func viewControllerOnDisplay() -> UIViewController?
    {
        if (viewControllers.count <= currentIndex)
        {
            let viewController = viewControllers[currentIndex]
            return viewController
        }
        else if let dataSource = dataSource
        {
            let numberOfColumns = dataSource.numberOfCellsInCarousel(self)
            if (numberOfColumns > currentIndex)
            {
                let viewController = dataSource.carousel(self, cellForRowAtIndex: currentIndex)
                viewControllers.insert(viewController, atIndex: currentIndex)
                return viewController
            }
        }
        return nil
    }
    
    // MARK: Private methods
    private func removeAllSubviews()
    {
        for viewControllerToRemove in viewControllers
        {
            viewControllerToRemove.viewWillDisappear(false)
            viewControllerToRemove.view.removeFromSuperview()
            viewControllerToRemove.viewDidDisappear(false)
        }
        viewControllers.removeAll()
    }
    
}
