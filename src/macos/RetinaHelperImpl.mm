// file RetinaHelper.mm

#import "macos/RetinaHelperImpl.h"
#import <OpenGL/OpenGL.h>

#import "wx/window.h"

@implementation RetinaHelperImpl

RetinaHelper::RetinaHelper(wxWindow* window) :
   _window(window)
{
   _self = nil;
   _self = [[RetinaHelperImpl alloc] initWithView:window->GetHandle() handler:window->GetEventHandler()];
}

RetinaHelper::~RetinaHelper()
{
  [(id)_self release];
}

void RetinaHelper::setViewWantsBestResolutionOpenGLSurface (bool aValue)
{
   [(id)_self setViewWantsBestResolutionOpenGLSurface:aValue];
}

bool RetinaHelper::getViewWantsBestResolutionOpenGLSurface()
{
   return [(id)_self getViewWantsBestResolutionOpenGLSurface];
}

float RetinaHelper::getBackingScaleFactor()
{
   return [(id)_self getBackingScaleFactor];
}


-(id)initWithView:(NSView *)aView handler:(wxEvtHandler *)aHandler
{
   self = [super init];
   if(self)
   {
      handler = aHandler;
      view = aView;
      // register for backing change notifications
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
      if(nc){
         [nc addObserver:self
                   selector:@selector(windowDidChangeBackingProperties:)
                         name:NSWindowDidChangeBackingPropertiesNotification
                      object:nil];
      }
   }
   return self;
}

-(void) dealloc
{
   // unregister from all notifications
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   if(nc){
      [nc removeObserver:self];
   }
   [super dealloc];
}

-(void)setViewWantsBestResolutionOpenGLSurface:(BOOL)value
{
   [view setWantsBestResolutionOpenGLSurface:value];
}

-(BOOL)getViewWantsBestResolutionOpenGLSurface
{
   return [view wantsBestResolutionOpenGLSurface];
}

-(float)getBackingScaleFactor
{
   return [[view window] backingScaleFactor];
}

- (void)windowDidChangeBackingProperties:(NSNotification *)notification {
   NSWindow *theWindow = (NSWindow *)[notification object];
   if(theWindow == [view window])
   {
      CGFloat newBackingScaleFactor = [theWindow backingScaleFactor];
      CGFloat oldBackingScaleFactor = [[[notification userInfo]
                                                         objectForKey:@"NSBackingPropertyOldScaleFactorKey"]
                                                       doubleValue];
      if (newBackingScaleFactor != oldBackingScaleFactor) {
         // generate a wx resize event and pass it to the handler's queue
         wxSizeEvent *event = new wxSizeEvent();
         // use the following line if this resize event should have the physical pixel resolution
         // but that is not recommended, because ordinary resize events won't do so either
         // which would necessitate a case-by-case switch in the resize handler method.
         // NSRect nsrect = [view convertRectToBacking:[view bounds]];
         NSRect nsrect = [view bounds];
         wxRect rect = wxRect(nsrect.origin.x, nsrect.origin.y, nsrect.size.width, nsrect.size.height);
         event->SetRect(rect);
         event->SetSize(rect.GetSize());
         handler->QueueEvent(event);
      }
   }
}
@end


