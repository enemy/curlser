Curlser -- Emulating browser with CURL
======================================


Rails specific reatures:

* Extracts and uses Ruby on Rails CSRF token
* When following redirects, Curlser does not violate RFC 2616/10.3.3 (switch from POST to GET in 302)
	* After POST, follow redirection and keep the request POST to address ERROR WEBrick::HTTPStatus::LengthRequired
	* This might not be a good idea, see TODÖ

Other features:

* Stores cookies
* Sets referrer automatically
* Stores responses in working dir



Example
-------

	require 'curlser'

	c = Curlser.new("http://localhost:3000")

	c.get "/"
	c.post "/users/sign_in", { "user[login]" => "quentin",
	                           "user[password]" => "monkey" }

	c.get "/"

	# Now, this should be the response for the signed in user
	puts c.responses.last


TODO
----

* Deal with POST->GET in 302 without exploding WEBrick and others
* Rewrite with curb?
