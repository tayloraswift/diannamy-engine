let container:UI.Element.Div = 
{
    let top:UI.Element.Div = 
    {
        let header:UI.Element.Div = 
        {
            let date:UI.Element.P = .init(
                [
                    .init("Tuesday, August 6, 2019")
                ],
                identifier: "time", classes: ["status"])
            let logo:UI.Element.P = .init(
                [
                    .init("The New York Times")
                ],
                identifier: "logo")
            let label:UI.Element.P = .init(
                [
                    .init("Today’s Paper")
                ],
                classes: ["status"])
            
            return .init([date, logo, label], identifier: "banner")
        }()
        let masthead:UI.Element.Div = 
        {
            let labels:[String] = 
            [
                "World",
                "U.S.",
                "Politics",
                "N.Y.",
                "Business",
                "Opinion",
                "Tech",
                "Science",
                "Health",
                "Sports",
                "Arts",
                "Books",
                "Style",
                "Food",
                "Travel",
                "Magazine",
                "T Magazine",
                "Real Estate",
                "Video",
            ]
            let items:[UI.Element.P] = labels.map{ .init([.init($0)]) }
            return .init(items, identifier: "masthead")
        }()
        
        return .init([header, masthead], identifier: "top")
    }()
    
    let body:UI.Element.Div 
    do 
    {
        let main:UI.Element.Div 
        do
        {
            let story1:UI.Element.Div 
            do 
            {
                let left:UI.Element.Div 
                do 
                {
                    let subtitle:UI.Element.P = .init(
                        [
                            .init("GUN VIOLENCE")
                        ], 
                        classes: ["topic"])
                    let title:UI.Element.P = .init(
                        [
                            .init("After Two Mass Shootings, Will Republicans Take a New Stance on Guns?")
                        ], 
                        classes: ["headline", "headline-major"])
                    let p1:UI.Element.P = .init(
                        [
                            .init("President Trump explored whether to expand background checks for guns, and Senator Mitch McConnell signaled he would be open to considering the idea.")
                        ])
                    let p2:UI.Element.P = .init(
                        [
                            .init("Both have opposed such legislation in the past. Their willingness to weigh it now suggests Republicans feel pressured to act after two mass shootings.")
                        ])
                    let statusbar:UI.Element.P = .init(
                        [
                            .init("Live", classes: ["accent", "strong"]), 
                            .init("9m ago", classes: ["accent", "strong"]), 
                            .init("595 comments"), 
                        ], 
                        classes: ["statusbar"])
                    
                    left = .init([subtitle, title, p1, p2, statusbar], style: .init([.grow: 1 as Float]))
                }
                
                let right:UI.Element.Div 
                do 
                {
                    let top:UI.Element.Div, 
                        bottom:UI.Element.Div 
                    
                    do 
                    {
                        let illustration:UI.Element.Div
                        do 
                        {
                            let picture:UI.Element.Div = .init([], classes: ["image-placeholder"])
                            let caption:UI.Element.P = .init(
                                [
                                    .init("A vigil for victims of the mass shootings in El Paso and Dayton was held outside the National Rifle Association’s headquarters in Fairfax, Va., on Monday.")
                                ], 
                                classes: ["caption"])
                            let creditline:UI.Element.P = .init(
                                [
                                    .init("Anna Moneymaker/The New York Times")
                                ], 
                                classes: ["credit-line"])
                            
                            illustration = .init([picture, caption, creditline], classes: ["illustration"], style: .init([.grow: 2 as Float]))
                        }
                        let right:UI.Element.Div
                        do 
                        {
                            let title:UI.Element.P = .init(
                                [
                                    .init("Will Shootings Sway Voters? Look First to Virginia Races")
                                ], 
                                classes: ["headline"])
                            let p1:UI.Element.P = .init(
                                [
                                    .init("The state’s elections in November will test the potency of gun rights as a voting issue.")
                                ])
                            let statusbar:UI.Element.P = .init(
                                [
                                    .init("5m ago"), 
                                    .init("87 comments"), 
                                ], 
                                classes: ["statusbar"])
                            right = .init([title, p1, statusbar])
                        }
                        
                        top = .init([illustration, right], style: .init([.axis: UI.Style.Axis.horizontal]))
                    }
                    do 
                    {
                        let title:UI.Element.P = .init(
                            [
                                .init("In the weeks before the El Paso shooting, the suspect’s mother called the police about a gun he had ordered.")
                            ], 
                            classes: ["headline"])
                        let statusbar:UI.Element.P = .init(
                            [
                                .init("5h ago")
                            ], 
                            classes: ["statusbar"])
                        bottom = .init([title, statusbar])
                    }
                    
                    
                    right = .init([top, bottom], style: .init([.grow: 2 as Float]))
                }
                
                story1 = .init([left, right], classes: ["story"], style: .init([.axis: UI.Style.Axis.horizontal]))
            }
            
            
            main = .init([story1], identifier: "main-panel")
        }
        
        let side:UI.Element.Div 
        do
        {
            let section:UI.Element.P = .init(
                [
                    .init("Opinion >")
                ], 
                identifier: "opinion-header")
            let author:UI.Element.P = .init(
                [
                    .init("Sahil Chinoy")
                ], 
                classes: ["author"])
            let title:UI.Element.P = .init(
                [
                    .init("Quiz: Let Us Predict Whether You’re a Democrat or a Republican")
                ], 
                classes: ["headline"])
            let summary:UI.Element.P = .init(
                [
                    .init("Just a handful of questions are very likely to reveal how you vote.")
                ])
            let statusbar:UI.Element.P = .init(
                [
                    .init("1h ago"), 
                    .init("1107 comments"), 
                ], 
                classes: ["statusbar"])
            
            side = .init([section, author, title, summary, statusbar], identifier: "side-panel")
        }
        
        body = .init([main, side], identifier: "page-body")
    }
    
    
    return .init([top, body], identifier: "container")
}()
