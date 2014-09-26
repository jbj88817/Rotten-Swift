import UIKit

class MovieViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate {
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var networkErrorView: UIView!

    var movies :[NSDictionary]=[]

    var filterMovies :[NSDictionary]=[]

    var refreshControl = UIRefreshControl()


    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self

        networkErrorView.alpha = 0;
        networkErrorView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.8)

        searchDisplayController!.searchBar.barTintColor = UIColor.blackColor()

        refreshControl.backgroundColor = UIColor.blackColor()
        refreshControl.tintColor = UIColor.colorWithRGBHex(0xFFCC00)
        refreshControl.addTarget(self, action: "refreshMovieList", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)

        tableView.registerNib(UINib(nibName: "MovieCell", bundle: nil), forCellReuseIdentifier: "MovieCell")

        searchDisplayController!.searchResultsTableView.registerNib(UINib(nibName: "MovieCell", bundle: nil), forCellReuseIdentifier: "MovieCell")

        refreshMovieList()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if tableView.indexPathForSelectedRow() != nil {
            tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow()!, animated: true)
        }
    }

    func refreshMovieList() {
        var progressView = MRProgressOverlayView.showOverlayAddedTo(self.view, animated: false)
        progressView.tintColor = UIColor.colorWithRGBHex(0xFFCC00)

        var url = "http://api.rottentomatoes.com/api/public/v1.0/lists/movies/box_office.json?apikey=renaqk7mwx4v3vfj3g67xmcj&limit=20&country=us"
        var request = NSURLRequest(URL: NSURL(string:url))
        var session = NSURLSession.sharedSession()
        session.dataTaskWithRequest(request,
            completionHandler: {(data: NSData!, response: NSURLResponse!, error: NSError!) in
                self.refreshControl.endRefreshing()

                if error == nil {

                    dispatch_async(dispatch_get_main_queue()) {
                        MRProgressOverlayView.dismissOverlayForView(self.view, animated: false)
                        var object = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as NSDictionary
                        self.movies = object["movies"] as [NSDictionary]
                        self.tableView.reloadData()
                    }
                }
                else {
                    self.showNetworkError()
                }

        }).resume()

    }


    func filterContentForSearchText(searchText: String, scope: String = "All") {
        if (searchText.isEmpty) {
            return
        }

        var searchURL = "http://api.rottentomatoes.com/api/public/v1.0/movies.json?q=" + searchText + "&page_limit=10&page=1&apikey=renaqk7mwx4v3vfj3g67xmcj"
        var request = NSURLRequest(URL: NSURL(string:searchURL))
        var session = NSURLSession.sharedSession()
        session.dataTaskWithRequest(request,
            completionHandler: {(data: NSData!, response: NSURLResponse!, error: NSError!) in

                if error == nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        var object = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as NSDictionary
                        var movieArray = object["movies"] as? [NSDictionary]
                        if let mArray = movieArray {
                            self.filterMovies = mArray
                            self.searchDisplayController!.searchResultsTableView.reloadData()
                        }
                    }
                }
                else {
                    self.showNetworkError()
                }

        }).resume()
    }

    func showNetworkError() {
        dispatch_async(dispatch_get_main_queue()) {
            MRProgressOverlayView.dismissOverlayForView(self.view, animated: false)

            self.networkErrorView.alpha = 1
            let offset = 3.0
            UIView.animateWithDuration(offset, animations: {
                self.networkErrorView.alpha = 0
            })
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func searchDisplayController(controller: UISearchDisplayController!, shouldReloadTableForSearchString searchString: String!) -> Bool {
        self.filterContentForSearchText(searchString, scope: "")
        return true
    }

    func searchDisplayController(controller: UISearchDisplayController!,
        shouldReloadTableForSearchScope searchOption: Int) -> Bool {
        self.filterContentForSearchText(self.searchDisplayController!.searchBar.text, scope: "")
        return true
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var movie :NSDictionary = NSDictionary()
        if tableView == self.searchDisplayController!.searchResultsTableView {
            movie = filterMovies[indexPath.row]
        }
        else {
            movie = movies[indexPath.row]
        }
        var movieId = movie["id"] as String
        performSegueWithIdentifier("detailView", sender: movieId)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "detailView") {
            let detailVC = segue.destinationViewController as DetailViewController
            detailVC.movieId = sender as String
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 129.0
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if tableView == self.searchDisplayController!.searchResultsTableView {
            return filterMovies.count
        } else {
            return movies.count
        }
    }

    func fadeInImage (view :UIView) {
        let movieCell = view as MovieCell
        UIView.beginAnimations("fade in", context: nil)
        UIView.setAnimationDuration(1.5)
        movieCell.posterView.alpha = 1
        UIView.commitAnimations()
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        var cell = tableView.dequeueReusableCellWithIdentifier("MovieCell") as MovieCell

        cell.accessoryType = UITableViewCellAccessoryType.None

        var customSelectionView = UIView(frame: cell.frame)
        customSelectionView.backgroundColor = UIColor.colorWithRGBHex(0xFFCC00)
        cell.selectedBackgroundView = customSelectionView

        cell.posterView.alpha = 0

        var movie :NSDictionary = NSDictionary()

        if tableView == self.searchDisplayController!.searchResultsTableView {
            movie = filterMovies[indexPath.row]
        } else {
            movie = movies[indexPath.row]
        }

        cell.movieTitleLabel.text = movie["title"] as? String
        cell.synopsisLabel.text = movie["synopsis"] as? String

        var posters = movie["posters"] as NSDictionary
        var posterUrl = posters["thumbnail"] as String

        var image = SDImageCache.sharedImageCache().imageFromDiskCacheForKey(posterUrl)
        if image != nil {
            println("cached in disk")
            cell.posterView.image = image
            fadeInImage(cell)
            return cell
        }

        var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        cell.posterView.addSubview(activityIndicator)
        activityIndicator.center = cell.posterView.center
        activityIndicator.startAnimating()

        SDWebImageDownloader.sharedDownloader().downloadImageWithURL(NSURL(string: posterUrl), options: nil, progress: nil, completed: {[weak self] (image, data, error, finished) in
            activityIndicator.removeFromSuperview()
            if let wSelf = self {
                if image != nil {
                    cell.posterView.image = image
                    wSelf.fadeInImage(cell)
                    SDImageCache.sharedImageCache().storeImage(image, forKey: posterUrl, toDisk: true)
                }
            }
        })

        return cell
    }
}
