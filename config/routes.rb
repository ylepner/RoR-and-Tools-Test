Rails.application.routes.draw do
  namespace :v1 do
    post "user/check_status", to: "user_checks#check_status"
  end
end
