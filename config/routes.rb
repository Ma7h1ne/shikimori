require 'sidekiq/web'

Rails.application.routes.draw do
  user_id = /(?: [^\/.] (?! \.rss$) | [^\/] (?= \.) | \.(?! rss$) )+/x

  ani_manga_format = "(/type/:type)(/status/:status)(/season/:season)\
(/genre/:genre)(/studio/:studio)(/publisher/:publisher)(/duration/:duration)\
(/rating/:rating)(/score/:score)(/options/:options)(/mylist/:mylist)\
(/search/:search)(/order-by/:order)(/page/:page)(.:format)"

  concern :db_entry do |options|
    member do
      get :favoured
      get 'tooltip(/:minified)' => :tooltip, as: :tooltip, minified: /minified/
      get 'edit/:field' => :edit_field, as: :edit_field, field: options[:fields]
      get 'versions/page/:page' => :versions, as: :versions
    end
  end
  concern :autocompletable do
    get :autocomplete, on: :collection, format: :json
  end
  concern :searcheable do
    get 'search/:search(/page/:page)' => :index, as: :search, on: :collection,
      constraints: { page: /\d+/ }
  end

  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'users/registrations',
    passwords: 'users/passwords'
  }

  # do not move these autocompletable concerns into resources definition.
  # they will confict with resource#show routes
  resources :animes, only: [], concerns: %i[autocompletable]
  resources :mangas, only: [], concerns: %i[autocompletable]
  resources :ranobe, only: [], concerns: %i[autocompletable]
  resources :characters, only: [], concerns: %i[autocompletable]
  resources :people, only: [], concerns: %i[autocompletable]
  resources :seyu, only: [], concerns: %i[autocompletable]
  resources :users, only: [], concerns: %i[autocompletable]
  resources :clubs, only: [], concerns: %i[autocompletable]

  resources :pages, path: '/', only: [] do
    collection do
      get :info
      get :privacy
      get :page404
      get :page503
      get :raise_exception
      get :timeout_120s
      get :my_target_ad

      get :bb_codes
      get :feedback
      get 'apanel' => :admin_panel
    end
  end

  resources :user_images, only: %i[create] # TODO: remove after 01.01.2016
  resources :messages, only: %i[create] do
    post :preview, on: :collection
  end

  resources :emails, only: [] do
    collection do
      post :bounce
      post :spam
    end
  end

  resources :comments, except: %i[create update] do
    # NOTE: must be before collection & member actions
    resources :bans, only: %i[new], controller: 'moderations/bans'
    resources :abuse_requests, controller: 'moderations/abuse_requests', only: [] do
      resources :bans, only: %i[new], controller: 'moderations/bans'

      collection do
        post :abuse
        post :spoiler
        post :offtopic
        post :summary
      end
    end

    collection do
      get :smileys
      post :preview
      get 'fetch/:comment_id/:topic_type/:topic_id(/:is_summary)/:skip/:limit' => :fetch, as: :fetch, topic_type: /Topic|User/
      # get ':commentable_type/:commentable_id(/:is_summary)/:offset/:limit', action: :postloader, as: :model
    end

    member do
      get :reply
      get :tooltip
    end
  end
  get 'comments/chosen/:ids(/:order)' => 'comments#chosen', as: :comments_chosen

  resources :spnsrs, only: %i[show]

  namespace :moderations do
    resources :users, only: %i[index]
    resources :versions, only: %i[show create destroy] do
      get '(/:type)(/page/:page)' => :index,
        as: '',
        on: :collection,
        type: /content|anime_video/
      member do
        get :tooltip
        post :accept
        post :take
        post :reject
        post :accept_taken
        post :take_accepted
      end
    end

    resources :bans, only: %i[create] do
      get '(/page/:page)' => :index, as: '', on: :collection
    end
    resources :abuse_requests, only: %i[show] do
      get '(/page/:page)' => :index, as: '', on: :collection

      member do
        post :take
        post :deny
      end
    end
    resources :reviews, only: [] do
      get '(/page/:page)' => :index, as: '', on: :collection

      member do
        post :accept
        post :reject
      end
    end
    resources :collections, only: [] do
      get '(/page/:page)' => :index, as: '', on: :collection

      member do
        post :accept
        post :reject
      end
    end

    resources :anime_video_reports, only: %i[create] do
      get '(/page/:page)' => :index, as: '', on: :collection

      member do
        %i(accept accept_edit accept_broken close_edit reject work cancel).each do |method|
          post method
          get method
        end
      end
    end

    resources :anime_video_authors, only: %i[index edit update show]
  end

  # api
  apipie
  # v2
  namespace :api, defaults: { format: 'json' } do
    namespace :v2 do
      resources :user_rates, only: %i[show index create update destroy] do
        post :increment, on: :member
      end
      namespace :topics do
        scope ':topic_id'  do
          resource :ignore, only: %i[create destroy]
        end
      end
      namespace :users do
        scope ':user_id'  do
          resource :ignore, only: %i[create destroy]
        end
      end
    end
  end
  # v1
  namespace :api, defaults: { format: 'json' } do
    scope module: :v1 do
      resources :animes, only: %i[show index] do
        member do
          get :roles
          get :similar
          get :related
          get :screenshots
          get :franchise
          get :videos
          get :external_links
        end
        get :search, on: :collection

        resources :anime_videos, only: %i[index create destroy]
        resources :videos, only: %i[index create destroy]
      end
      resource :calendar, only: %i[show]
      %i[mangas ranobe].each do |kind|
        resources kind, only: %i[show index] do
          member do
            get :roles
            get :similar
            get :related
            get :franchise
            get :external_links
          end
          get :search, on: :collection
        end
      end

      resources :devices, only: %i[create update index destroy] do
        get :test, on: :member
      end
      resources :characters, only: %i[show] do
        get :search, on: :collection
      end
      resources :people, only: %i[show] do
        get :search, on: :collection
      end

      resources :studios, only: %i[index]
      resources :genres, only: %i[index]
      resources :publishers, only: %i[index]

      resources :forums, only: %i[index]
      resources :topics, only: %i[index show]
      resources :comments, only: %i[show index create update destroy]

      resources :topic_ignores, only: %i[create destroy]
      resources :user_images, only: %i[create]

      resources :clubs, only: %i[show index] do
        member do
          get :members
          get :animes
          get :mangas
          get :ranobe
          get :characters
          get :images

          post :join
          post :leave
        end
      end

      resources :messages, only: %i[show create update destroy] do
        collection do
          post :mark_read
          post :delete_all
          post :read_all
        end
      end

      resources :user_rates, only: %i[show create update destroy] do
        post :increment, on: :member

        collection do
          scope ':type', type: /anime|manga/ do
            delete :cleanup
            delete :reset
          end
        end
      end
      resources :nickname_changes, only: [] do
        delete :cleanup, on: :collection
      end

      resource :access_token, only: %i[show create]
      resource :authenticity_token, only: %i[show]

      resources :bans, only: %i[index]

      devise_scope :user do
        resources :sessions, only: %i[create]
      end

      resources :users, only: %i[index show], constraints: { id: user_id } do
        collection do
          get :whoami
        end
        member do
          get :info
          get :friends
          get :clubs
          get :favourites
          get :messages
          get :unread_messages
          get :history
          get :anime_rates
          get :manga_rates
          get :bans
          get :anime_video_reports
        end
      end

      resources :appears, only: %i[create], controller: 'appear'
      resources :friends, only: [] do
        post '/', action: :create, on: :member
        delete '/', action: :destroy, on: :member
      end
      resources :ignores, only: [] do
        post '/', action: :create, on: :member
        delete '/', action: :destroy, on: :member
      end

      resources :dialogs, only: %i[index show destroy]
      resources :stats, only: [] do
        get :active_users, on: :collection
      end

      resources :constants do
        collection do
          get :anime
          get :manga
          get :user_rate
          get :club
          get :smileys
        end
      end

      resources :styles, only: %i[show create update] do #, :destroy
        post :preview, on: :collection
      end
      resources :achievements, only: %i[index]
    end
  end
  # /api

  constraints MangaOnlineDomain do
    get '/', to: 'manga_online/mangas#index'
    get 'mangas/:id' => 'manga_online/mangas#show', as: :online_manga_show
    get 'chapters/:id(/:page)' => 'manga_online/chapters#show', as: :online_manga_chapter_show

    get 'robots.txt' => 'robots#manga_online'
  end

  constraints AnimeOnlineDomain do
    get '/', to: 'anime_online/dashboard#show'
    get '/page/:page', to: 'anime_online/dashboard#show', as: :anime_dashboard_page

    get 'pingmedia_test_1', to: 'anime_online/dashboard#pingmedia_test_1', as: :pingmedia_test_1
    get 'pingmedia_test_2', to: 'anime_online/dashboard#pingmedia_test_2', as: :pingmedia_test_2
    get 'advertur_test', to: 'anime_online/dashboard#advertur_test', as: :advertur_test
    get 'advertur_test_2', to: 'anime_online/dashboard#advertur_test_2', as: :advertur_test_2

    get "animes#{ani_manga_format}" => "animes_collection#index", klass: 'anime',
      with_video: '1', constraints: { page: /\d+/, studio: /[^\/]+/ }

    scope '', module: 'anime_online' do
      resources :anime_video_authors, only: [], concerns: %i[autocompletable]

      scope 'animes/:anime_id' do
        get '' => redirect { |params, request| "#{request.url}/video_online" }

        resources :video_online, controller: 'anime_videos', except: %i[show] do
          member do
            post :track_view
            post :viewed
          end

          collection do
            get :help
            get '(/:episode)(/:video_id)', action: :index, as: :play,
              episode: /\d+/, video_id: /\d+/
            post :extract_url
            get :extract_url if Rails.env.development?
          end
        end
      end
    end

    get 'robots.txt' => 'robots#anime_online'
  end

  constraints ShikimoriDomain do
    root to: 'dashboards#show'
    get '/', to: 'dashboards#show', as: :new_session
    get '/page/:page', to: 'dashboards#show', as: :root_page

    # seo redirects
    get 'r' => redirect('/reviews')
    constraints other: /.*/  do
      get 'r/:other' => redirect { |params, request| "/reviews/#{params[:other]}" }
      get 'person/:other' => redirect { |params, request| "/people/#{params[:other]}" }
    end
    constraints forum: /a|m|c|p|s|f|o|g|reviews|cosplay|v|news|games|vn/, format: /html|json|rss/ do
      get ':forum(/s-:linked)/new' => redirect { |_, request| "/forum#{request.path}" }
      get ':forum(/s-:linked)(/p-:page)' => redirect { |_, request| "/forum#{request.path}" }
      get ':forum(/s-:linked)/:id' => redirect { |_, request| "/forum#{request.path}" }
    end
    {
      o: %i[offtopic s],
      s: %i[site s],
      g: %i[clubs s],
      v: %i[contests s],
      a: %i[animanga anime],
      m: %i[animanga manga],
      c: %i[animanga character],
      p: %i[animanga person]
    }.each do |old_path, (new_path, linked)|
      scope "forum/#{old_path}(/s-:linked)", format: /html|json|rss/ do
        ['/new', '(/p-:page)', '/:id'].each do |path|
          get path => redirect { |_, request|
            request.path
              .gsub(%r(/#{old_path}(/|$)), "/#{new_path}" + '\1')
              .gsub(%r(/s-), "/#{linked}-")
          }
        end
      end
    end
    # /seo redirects

    resources :topics, only: [] do
      get :reload, format: /json/, on: :member
    end

    scope :forum do
      resources :topics, except: %i[index show new]

      get '/' => 'topics#index',  as: :forum
      scope(
        '(/:forum)(/:linked_type-:linked_id)',
        forum: /animanga|site|offtopic|clubs|my_clubs|reviews|cosplay|contests|news|updates|games|vn|collections/,
        linked_type: /anime|manga|ranobe|character|person|club|contest|collection|cosplay_gallery/,
        format: /html|json|rss/
      ) do
        get '/new' => 'topics#new', as: :new_topic
        get '(/p-:page)' => 'topics#index', as: :forum_topics
        get '/:id' => 'topics#show',  as: :forum_topic
      end
    end

    get 'topics/chosen/:ids' => 'topics#chosen', as: :topics_chosen
    get 'topics/:id/tooltip(/:test)' => 'topics#tooltip', as: :topic_tooltip

    # favourites
    post 'favourites/:linked_type/:linked_id' => 'favourites#create', as: :favourites
    delete 'favourites/:linked_type/:linked_id' => 'favourites#destroy'

    post 'favourites/seyu/:linked_type/:linked_id' => 'favourites#create', kind: Favourite::Seyu, as: :favourites_seyu
    delete 'favourites/seyu/:linked_type/:linked_id' => 'favourites#destroy', kind: Favourite::Seyu

    post 'favourites/producer/:linked_type/:linked_id' => 'favourites#create', kind: Favourite::Producer, as: :favourites_producer
    delete 'favourites/producer/:linked_type/:linked_id' => 'favourites#destroy', kind: Favourite::Producer

    post 'favourites/mangaka/:linked_type/:linked_id' => 'favourites#create', kind: Favourite::Mangaka, as: :favourites_mangaka
    delete 'favourites/mangaka/:linked_type/:linked_id' => 'favourites#destroy', kind: Favourite::Mangaka

    post 'favourites/person/:linked_type/:linked_id' => 'favourites#create', kind: Favourite::Person, as: :favourites_person
    delete 'favourites/person/:linked_type/:linked_id' => 'favourites#destroy', kind: Favourite::Person

    resources :cosplay_galleries, only: [] do
      get :publishing, on: :collection
      post :publish, on: :member
    end

    resource :translations, only: [] do
      get :anime, action: :show, anime: true
      get :manga, action: :show, manga: true
    end

    resources :clubs, except: %i[edit destroy] do
      member do
        get 'members(/page/:page)' => :members, as: :members
        get :animes
        get :mangas
        get :ranobe
        get :characters
        get :images

        get 'edit/:page' => :edit,
          as: :edit,
          page: /main|description|links|members|styles|pages/
      end

      collection do
        get '(/p-:page)' => 'clubs#index', as: ''
      end

      resources :club_roles, only: %i[create destroy], concerns: %i[autocompletable]
      resources :club_invites, only: %i[create]

      resource :comments, only: [], module: :clubs do
        get :broadcast
      end

      resources :club_images, only: %i[create destroy], module: :clubs
      resources :club_pages, except: %i[index], module: :clubs, path: 'pages' do
        post :up, on: :member
        post :down, on: :member
      end
      resources :club_topics, except: %i[destroy], module: :clubs, path: 'topics' do
        get '(/p-:page)' => 'club_topics#index', as: '', on: :collection
      end
    end

    resources :collections do
      get '(/p-:page)' => 'collections#index', as: '', on: :collection
    end

    resources :club_invites, only: [] do
      post :accept, on: :member
      post :reject, on: :member
    end

    # statistics
    get 'anime-history' => redirect('/anime-industry')
    get 'anime-industry' => 'statistics#index', as: :anime_statistics

    # site pages
    resources :pages, path: '/', only: [] do
      collection do
        get :ongoings
        get :about
        get :development

        get :terms
        get :privacy
        get :for_right_holders
        get :user_agent

        get 'site-news' => redirect('/news_feed.rss')
        get 'anime-news' => redirect('/news_feed.rss')

        get :news_feed, format: :rss

        get :disabled_registration
        get :disabled_openid
        get :tableau
      end
    end

    resource :moderations, only: %i[show] do
      collection do
        get :missing_screenshots

        scope kind: /all|vk|vk_subbed|vk_dubbed|subbed|dubbed/ do
          get 'missing_videos(/:kind)' => :missing_videos, as: :missing_videos
          get 'missing_videos/:kind/episodes/:anime_id' => :missing_episodes, as: :missing_episodes
        end
      end
    end

    resource :tests, only: %i[show] do
      get :echo
      post :echo

      get :momentjs
      get :border
      get 'd3/:anime_id' => :d3, as: :d3
      get :webm
      get :animes
      get :wall
      get :ajax
      get :vk_video
      get :colors
      get :vue
      #get 'd3/:anime_id/data' => :d3_data, as: :d3_data, format: :json
    end

    # картинки с danbooru
    resources :danbooru, only: [], concerns: %i[autocompletable] do
      get 'yandere/:url' => :yandere, url: /.*/, on: :collection
    end

    # cosplay
    constraints id: /\d[^\/]*?/ do
      resources :cosplay, path: '/cosplay' do
        get :mod, on: :collection

        resources :cosplay_galleries, path: '', controller: 'cosplay' do
          get :delete
          get :undelete
        end
      end
    end

    # cosplayers
    get 'cosplay/:gallery/comments' => 'cosplayers#comments', as: :cosplay_comments
    get 'cosplay' => 'cosplayers#index', as: :cosplayers
    get 'cosplay/:cosplayer(/:gallery)' => 'cosplayers#show', as: :cosplayer

    resources :forums, only: %i[index edit] do
      patch :update, on: :member, as: :update
    end
    resources :genres, only: %i[index edit update] do
      get :tooltip, on: :member
    end

    # seo redirects
    constraints kind: /animes|mangas/, other: /.*/, other2: /.*/ do
      get ':kind/status/planned:other' => redirect { |params, request| "/#{params[:kind]}/status/anons#{params[:other]}" }
      get ':kind/:other/status/planned:other2' => redirect { |params, request| "/#{params[:kind]}/#{params[:other]}/status/anons#{params[:other2]}" }
      get ':kind/season/planned:other' => redirect { |params, request| "/#{params[:kind]}/status/anons#{params[:other]}" }
      get ':kind/season/ongoing:other' => redirect { |params, request| "/#{params[:kind]}/status/ongoing#{params[:other]}" }
      get ':kind/season/latest:other' => redirect { |params, request| "/#{params[:kind]}/status/latest#{params[:other]}" }
      constraints type: /Anime|translation_planned/ do
        get ':kind/type/:type:other' => redirect { |params, request| "/#{params[:kind]}#{params[:other]}" }
      end
    end
    # /seo redirects

    # аниме и манга
    %w[animes mangas ranobe].each do |kind|
      get "#{kind}#{ani_manga_format}" => 'animes_collection#index',
        as: "#{kind}_collection",
        klass: kind.singularize,
        constraints: { page: /\d+/, studio: /[^\/]+/ }

      get "#{kind}/menu(/rating/:rating)" => 'animes_collection#menu',
        as: "menu_#{kind}", klass: kind.singularize

      resources kind, only: %i[show], format: /html/ do
        member do
          get :characters
          get :staff
          get :files if kind == 'animes'
          get :similar
          get :screenshots
          get :videos
          get 'cosplay(/page/:page)' => :cosplay, as: :cosplay

          get :related
          get :chronology
          get :franchise

          get :art
          get :images
          get :clubs

          get :summaries

          get :other_names # другие названия
          get :resources # подгружаемый центральный блок с персонажами, скриншотами, видео

          get :stats
          get :recent

          # инфо по торрентам эпизодов
          get :episode_torrents

          get 'cosplay/:anything' => redirect { |params, request| "/#{kind}/#{params[:id]}/cosplay" }, anything: /.*/
        end

        # обзоры
        resources :reviews, type: kind.singularize.capitalize, except: [:show]
      end
    end

    resources :user_rates, only: %i[edit]

    resources :animes, only: %i[edit update] do
      concerns :db_entry, fields: Regexp.new(%w{
        name russian synonyms description_ru description_en image
        kind episodes rating
        screenshots videos torrents_name tags aired_on released_on genres
        external_links
      }.join('|'))

      post 'torrent' => 'torrents#create', on: :member

      resources :screenshots, only: %i[create destroy] do
        post :reposition, on: :collection
      end
      resources :videos, only: %i[create destroy]
    end

    %i[mangas ranobe].each do |type|
      resources type, only: %i[edit update] do
        concerns :db_entry, fields: Regexp.new(%w{
          name russian synonyms description_ru description_en image
          kind rating volumes chapters
          tags aired_on released_on status genres
          external_links
        }.join('|'))
      end
    end

    resources :characters, only: %i[show edit update] do
      concerns :db_entry, fields: Regexp.new(%w{
        name russian japanese image description_ru description_en tags
      }.join('|'))
      concerns :searcheable

      member do
        get :seyu
        get :animes
        get :mangas
        get :ranobe
        get :art
        get :images
        get 'cosplay(/page/:page)' => :cosplay, as: :cosplay
        get :clubs
      end
    end

    resources :people, only: %i[show edit update] do
      concerns :db_entry, fields: Regexp.new(%w{
        name russian japanese image website birthday
      }.join('|'))
      concerns :searcheable

      member do
        get 'time' => redirect {|params, request| request.url.sub('/time', '') } # редирект со старых урлов
        get 'works(order-by/:order_by)' => :works, order_by: /date/, as: :works
      end
    end
    get 'producers/search/:search(/page/:page)' => 'people#index', as: :search_producers, kind: 'producer', constraints: { page: /\d+/ }
    get 'mangakas/search/:search(/page/:page)' => 'people#index', as: :search_mangakas, kind: 'mangaka', constraints: { page: /\d+/ }

    resources :seyu, only: %i[show edit update] do
      concerns :db_entry, fields: Regexp.new(%w{
        name russian japanese image website birthday
      }.join('|'))
      concerns :searcheable

      member do
        get 'roles(order-by/:order_by)' => :roles, order_by: /date/, as: :roles
      end
    end
    #get "people/:search(/page/:page)" => 'people#index', as: :people_search, constraints: { page: /\d+/ }
    #get "seyu/:id#{ani_manga_format}" => 'seyu#show', as: :seyu
    #get "mangaka/:id#{ani_manga_format}" => 'mangaka#show', as: :seyu

    # голосования
    resources :contests, except: %i[index] do
      collection do
        get :current
        get '(/page/:page)' => :index, as: ''
      end

      member do
        post :start
        post :build
        post :propose
        post :stop_propose
        post :cleanup_suggestions

        get :grid
        get 'rounds/:round', action: 'show', as: 'round'
        get 'rounds/:round/match/:match_id', action: 'show', as: 'round_match'
        get 'rounds/:round/match/:match_id/users', action: 'users', as: 'round_match_users'
      end

      resources :contest_suggestions, path: 'suggestions', only: %i[show create destroy]
      resources :contest_matches, path: 'matches', only: %i[show] do
        post 'vote/:variant' => 'contest_matches#vote', as: 'vote', on: :member
      end
    end

    # votes
    post 'votes/:type/:id/yes' => 'votes#create', voting: 'yes', as: :vote_yes
    post 'votes/:type/:id/no' => 'votes#create', voting: 'no', as: :vote_no

    get 'kakie-anime-postmotret' => 'recommendations#favourites',
      as: :recommendations_favourites_anime,
      action: :favourites,
      klass: Anime.name.downcase

    get 'kakuyu-mangu-pochitat' => 'recommendations#favourites',
      as: :recommendations_favourites_manga,
      action: :favourites,
      klass: Manga.name.downcase

    get 'kakie-ranobe-pochitat' => 'recommendations#favourites',
      as: :recommendations_favourites_ranobe,
      action: :favourites,
      klass: Ranobe.name.downcase

    # recommendations
    if Rails.env.development?
      get "recommendations/test(/:users(/:threshold))(/user/:user)" => 'recommendations#test',
        defaults: { users: 10, threshold: 0 }
    end

    get "recommendations/:klass(/:metric(/:threshold))(/user/:user)/#{ani_manga_format}" => 'recommendations#index',
      as: :recommendations,
      klass: /anime|manga|ranobe/,
      metric: /euclid|euclid_z|pearson|pearson_mean|pearson_z|svd|svd_z|svd_mean/,
      votes: /\d+/
    get "recommendations/anime" => 'recommendations#index', as: :recommendations_anime, klass: Anime.name.downcase
    get "recommendations/manga" => 'recommendations#index', as: :recommendations_manga, klass: Manga.name.downcase
    resources :recommendation_ignores, only: %i[create] do
      constraints target_type: /anime|manga/ do
        delete 'cleanup/:target_type', action: :cleanup, on: :collection, as: :cleanup
      end
    end

    # userlist comparer
    get "comparer/:list_type/:user_1/vs/:user_2#{ani_manga_format}" => 'userlist_comparer#show',
      as: :userlist_comparer,
      constraints: {
        list_type: /anime|manga/,
        user_1: /[^\/]+?/,
        user_2: /[^\/]+?/,
        format: /json/
      }

    resources :studios, only: %i[index]
    resources :proxies, only: %i[index]

    get 'sitemap' => 'sitemap#index'
    get 'robots.txt' => 'robots#shikimori'

    authenticate :user, lambda { |u| u.admin? } do
      mount Sidekiq::Web, at: 'sidekiq'
      mount PgHero::Engine, at: 'pghero'
    end

    if Rails.env.development?
      get 'users/by-id/:user_id' => 'users#statistics', type: 'statistics', kind: 'anime'
    end

    resources :user_tokens, only: %i[destroy]

    resources :users, only: %i[index] do
      collection do
        get '(/p-:page)' => 'users#index', as: ''
        get '/similar/:klass/(:threshold)(/page/:page)' => 'users#similar',
          as: 'similar',
          klass: /anime|manga/
      end
    end

    # messages edit & rss & email bounce
    # create & preview урлы объявлены выше, глобально
    resources :messages, only: %i[show edit update destroy] do
      collection do
        get 'chosen/:ids' => :chosen, as: :chosen

        get ':name/:key.rss' => 'messages#feed',
          format: :rss,
          type: 'notifications',
          name: /[^\/]+?/,
          as: :feed
        get ':name/:key/Private/unsubscribe' => 'messages#unsubscribe',
          name: /[^\/]+?/,
          kind: MessageType::Private,
          as: :unsubscribe
      end
    end

    resources :ignores, only: %i[create]
    resources :profiles, path: '/', constraints: { id: user_id }, only: %i[show update] do
      member do
        get :friends
        get :favourites
        get :clubs
        get :ban
        get :feed
        #get :stats
        get 'edit/:page' => :edit,
          as: :edit,
          page: /account|profile|password|styles|list|notifications|misc|ignored_topics|ignored_users/

        get 'reviews(/page/:page)' => :reviews, as: :reviews
        get 'comments(/page/:page)' => :comments, as: :comments
        scope 'comments' do
          get 'summaries(/page/:page)' => :summaries, as: :summaries
        end
        get 'versions(/page/:page)' => :versions, as: :versions
        get 'video/versions(/page/:page)' => :video_versions, as: :video_versions
        get 'video/uploads(/page/:page)' => :video_uploads, as: :video_uploads
        get 'video/reports(/page/:page)' => :video_reports, as: :video_reports
      end

      get 'manga' => redirect {|params, request| request.url.sub('/manga', '') } # редирект со старых урлов
      get 'list/history' => redirect {|params, request| request.url.sub('/list/history', '/history') } # редирект со старых урлов
      resources :user_history, only: [], path: '/history' do
        collection do
          get '(:page)' => :index, as: :index
          delete 'reset/:type' => :reset, as: :reset, type: /anime|manga/
        end
      end

      resources :user_rates, only: [], path: '/list' do
        collection do
          get ":list_type#{ani_manga_format}" => :index,
            as: '',
            list_type: /anime|manga/
          get ':list_type/export' => :export, as: :export
        end
      end

      resources :user_preferences, only: [] do
        patch :update, on: :collection
      end

      resources :dialogs, only: %i[index show destroy] do
        member do
          get 'page/:page' => :show, as: :show
          get 'reply/:reply_message_id' => :show, as: :reply
        end
        get '(page/:page)' => :index, as: :index, on: :collection
      end

      resources :messages, only: [], messages_type: /news|notifications|private/ do
        collection do
          get ':messages_type(/page/:page)' => :index, as: :index
        end
      end

      resources :achievements, only: %i[index] do
        get :franchise, on: :collection
      end

      scope module: :users do
        resources :list_imports, only: %i[new create show]
        resource :list_export, only: %i[show] do
          get :animes, format: /xml|json/
          get :mangas, format: /xml|json/
        end
      end
    end

    get 'log_in/restore' => "admin_log_in#restore", as: :restore_admin
    get 'log_in/:nickname' => "admin_log_in#log_in", nickname: /.*/

    get '*a', to: 'pages#page404' unless Rails.env.development?
  end
end
