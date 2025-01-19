import QueryAPI

struct CafeteriaItem {
    var id: Int
    var name: String
    var runningTime: String?
    var menu: [CafeteriaPageQuery.Data.Menu.Menu]
}
