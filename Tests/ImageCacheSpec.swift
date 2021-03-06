import Foundation
import Nimble
import Quick

@testable import SKImageCache

class ImageCacheSpec: QuickSpec {
    override func spec() {
        describe("ImageCache") {
            var delegate: MockImageCacheDelegate!
            var mockLocalImageController: MockLocalImageController!
            var mockNSCache: MockNSCache!
            var unitUnderTest: ImageCache!
            var url: URL!

            beforeEach {
                delegate = MockImageCacheDelegate()
                mockLocalImageController = MockLocalImageController()
                mockNSCache = MockNSCache()
                url = URL(string: "http://example.com/folder1/folder2/image1.png")!
                unitUnderTest = ImageCache(cache: mockNSCache, localFileController: mockLocalImageController)
                unitUnderTest.delegate = delegate
            }

            context("init()") {
                it("Should set a cache") {
                    unitUnderTest = ImageCache()
                    expect(unitUnderTest.cache).toNot(beNil())
                }
            }

            context("defaultImageDirectory: String") {
                it("Should return the value from the local image controller") {
                    mockLocalImageController.defaultImageDirectory = "testImageDirectory"
                    expect(unitUnderTest.defaultImageDirectory).to(equal("testImageDirectory"))
                }

                it("Should set the value on the local image controller") {
                    unitUnderTest.defaultImageDirectory = "testImageDirectory"
                    expect(mockLocalImageController.defaultImageDirectory).to(equal("testImageDirectory"))
                }
            }

            context("cacheImage(_:forURL:)") {
                var image: UIImage!

                beforeEach() {
                    let bundle = Bundle(for: type(of: self))
                    image = UIImage(named: "testimage", in: bundle, compatibleWith: nil)
                }

                it("Should not call set object on the cache if the image is nil") {
                    unitUnderTest.cacheImage(nil, forURL: url)
                    expect(mockNSCache.setObjectCalled).to(beFalse())
                }

                it("Should call set object on the cache if an image is provided") {
                    let bundle = Bundle(for: type(of: self))
                    let image = UIImage(named: "testimage", in: bundle, compatibleWith: nil)
                    unitUnderTest.cacheImage(image, forURL: url)
                    expect(mockNSCache.setObjectCalled).to(beTrue())
                }

                it("Should not call saveImage on the localFileController if useLocalStorage is set to false") {
                    unitUnderTest.useLocalStorage = false
                    unitUnderTest.cacheImage(image, forURL: url)
                    expect(mockLocalImageController.savePNGCalled).to(beFalse())
                }

                it("Should call saveImage on the localFileController if useLocalStorage is set to true") {
                    unitUnderTest.useLocalStorage = true
                    unitUnderTest.cacheImage(image, forURL: url)
                    expect(mockLocalImageController.savePNGCalled).to(beTrue())
                }
            }

            context("deleteDirectory(_:)") {
                it("Should call delete directory on the local file controller") {
                    unitUnderTest.deleteDirectory("")
                    expect(mockLocalImageController.deleteDirectoryCalled).to(beTrue())
                }
            }

            context("emptyCache()") {
                it("Should remove all items from the cache") {
                    unitUnderTest.emptyCache()
                    expect(mockNSCache.removeAllObjectsCalled).to(beTrue())
                }
            }

            context("getImage(url:skipCache:completion:)") {
                it("Should check the cache for an image") {
                    mockNSCache.shouldReturnImage = true
                    let _ = unitUnderTest.getImage(url: url, completion: { (_, _, _) in })
                    expect(mockNSCache.objectForKeyCalled).to(beTrue())
                }

                it("Should return a cached image through the closure if one exists") {
                    mockNSCache.shouldReturnImage = true
                    let _ = unitUnderTest.getImage(url: url, completion: { (image, _, _) in
                        expect(image).toNot(beNil())
                    })
                }

                it("Should return true for the from cache value if an image is returned from the cache") {
                    mockNSCache.shouldReturnImage = true
                    let _ = unitUnderTest.getImage(url: url, completion: { (_, source, _) in
                        expect(source).to(equal(.cache))
                    })
                }

                it("Should not return a value from the cache if skipCache is set to true.") {
                    mockNSCache.shouldReturnImage = true
                    waitUntil { done in
                        let _ = unitUnderTest.getImage(url: url, skipCache: true, completion: { (_, source, _) in
                            expect(source).to(equal(ImageCache.ImageSource.remote))
                            done()
                        })
                    }
                }

                it("Should call loadURL on the delegate if one is set") {
                    mockNSCache.shouldReturnImage = false
                    let _ = unitUnderTest.getImage(url: url, completion: { (_, fromCache, _) in })
                    expect(delegate.loadImageAtURLCalled).to(beTrue())
                }

                it("Should cache the image returned by the delegate at the provided URL before returning through the closure") {
                    unitUnderTest = ImageCache()
                    unitUnderTest.delegate = delegate

                    waitUntil { done in
                        let _ = unitUnderTest.getImage(url: url, completion: { (image, _, _) in
                            expect(unitUnderTest.cache.object(forKey: url.lastPathComponent as AnyObject)).to(be(image))
                            done()
                        })
                    }
                }

                it("Should not call getImage on the localFileController if skipCache is set to true") {
                    unitUnderTest.useLocalStorage = true
                    let _ = unitUnderTest.getImage(url: url, directory: nil, skipCache: true, completion: { (_, _, _) in
                        expect(mockLocalImageController.getImageCalled).to(beFalse())
                    })
                }

                it("Should call getImage on the localFileController if useLocalStorage is set to true") {
                    unitUnderTest.useLocalStorage = true
                    let _ = unitUnderTest.getImage(url: url, directory: nil, skipCache: false, completion: { (_, _, _) in
                        expect(mockLocalImageController.getImageCalled).to(beTrue())
                    })
                }

                it("Should set the source to local if an image is returned from the localFileController") {
                    unitUnderTest.useLocalStorage = true
                    let _ = unitUnderTest.getImage(url: url, directory: nil, skipCache: false, completion: { (_, source, _) in
                        expect(source).to(equal(.localStorage))
                    })
                }
            }

            context("imageNameFromURL(_:)") {
                it("Should return the last path component if useURLPathing is false") {
                    unitUnderTest.useURLPathing = false
                    let imageInfo = unitUnderTest.imageInfoFromURL(url)
                    let imageName = imageInfo.imageKey

                    expect((imageName as! String)).to(equal("image1.png"))
                }

                it("Should return the full image path if useURLPathing is false") {
                    unitUnderTest.useURLPathing = true
                    let imageInfo = unitUnderTest.imageInfoFromURL(url)
                    let imageName = imageInfo.imageKey

                    expect((imageName as! String)).to(equal("/folder1/folder2/image1.png"))
                }
            }

            context("removeObjectAtURL(_:)") {
                it("Should call remove object on the cache") {
                    unitUnderTest.removeObjectAtURL(url)
                    expect(mockNSCache.removeObjectCalled).to(beTrue())
                }
            }
        }
    }
}
