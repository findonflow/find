# Profile

Thea idea with the profile is that a user can register lots of relevant information about himself directly on the flow blockchian. 

The base profile fields include
 - name: max length 16
 - avatar
 - description: max 255 length
 - tags: max 3 short descriptione
 - collections: point to a capability for things like versus art of find bids
 - wallets: register wallets that support different types.
 - friends: you can add other users as friends
 - bans: you can ban users that you do not want to interact with
 - links: a very generic construct with title/type/url array of links. The title field has to be unique here. 
   
What types of links do i envision
 - if the type is a valid fa-icon then use it as that and only use the title as a hover over the image. 
 - if type is img then show it in a img tag
 - if type is audtio/video then show viewer for that. 
 - if type is collection and title is same as a collection this is a weblink to that collection.
 - if type is generic then just show a simple a href. 


