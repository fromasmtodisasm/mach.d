module mach.sdl.graphics.texture;

private:

import derelict.opengl3.gl;

import mach.traits : isNumeric;
import mach.misc.refcounter : RefCounter;
import mach.math.vector2 : Vector2;
import mach.math.box : Box;
import mach.sdl.error : GLError;
import mach.sdl.glenum : TextureTarget, TextureParam;
import mach.sdl.glenum : PixelsType, PixelsFormat;
import mach.sdl.glenum : GLPrimitive, VertexType, getvertextype, validvertextype;
import mach.sdl.graphics.surface : Surface;
import mach.sdl.graphics.pixelformat : SDLPixelFormat = PixelFormat;
import mach.sdl.graphics.vertex : Vertex, Vertexes, Vertexesf;

import mach.io.log;

public:

import mach.sdl.glenum : TextureWrap, TextureFilter;
import mach.sdl.glenum : TextureMinFilter, TextureMagFilter;



struct Texture{
    
    alias Name = uint;
    
    /// Texture name reference counting
    static RefCounter!Name refcounter; // TODO: Verify functionality
    static size_t expirednames;
    static size_t maxexpirednames = 16;
    
    Name name;
    uint width;
    uint height;
    PixelsFormat format;
    bool owned = true;
    
    static enum string AtomicMethodMixin = `
        static if(atomic){
            this.bind();
            scope(exit){
                this.unbind();
                GLError.enforce();
            }
        }
    `;
    
    this(in string path, in bool mipmap = false){
        Surface surface = Surface(path);
        scope(exit) surface.free();
        this(surface, mipmap);
    }
    this(Surface surface, in bool mipmap = false){
        log(surface.pixelformat.format);
        auto converted = surface.convert(SDLPixelFormat.Format.RGBA8888); // TODO: only convert when necessary
        scope(exit) converted.free();
        this(converted.pixels, converted.width, converted.height, mipmap, PixelsFormat.RGBA);
    }
    this(bool atomic = true, bool expire = true)(
        in void* pixels, int width, int height,
        in bool mipmap = false, PixelsFormat format = PixelsFormat.RGBA
    )in{
        assert((width > 0) & (height > 0), "Invalid texture size.");
    }body{
        static if(expire){
            if(expirednames > maxexpirednames) this.freeexpired();
        }
        
        this.width = width;
        this.height = height;
        this.format = format;
        
        glGenTextures(1, &this.name);
        refcounter.increment(this.name);
        
        mixin(AtomicMethodMixin); // Binds the texture
        
        this.wrap!false(TextureWrap.Repeat);
        this.filter!false(TextureFilter.Nearest);
        glTexImage2D(
            TextureTarget.Texture2D, 0, format,
            width, height, 0, format, GL_UNSIGNED_INT_8_8_8_8, pixels
        );
        
        if(mipmap) this.mipmap!false();
    }
    
    ~this(){
        if(this.name != 0) this.free();
    }
    
    this(this){
        if(this.name != 0) refcounter.increment(this.name);
    }
    
    void free(){
        if(this.name != 0){
            if(refcounter.decrement(this.name) == 0) expirednames++;
            this.name = 0;
        }
    }
    
    /// Freeing a texture only decrements a reference counter without actually
    /// deallocating any memory. Once a significant number of textures names
    /// have become expired, they are deallocated all at once by calling this.
    static void freeexpired(){
        refcounter.clean((in Name[] names){
            // Silently ignores invalid names
            glDeleteTextures(cast(int) names.length, names.ptr);
        });
        
    }
    
    /// Bind this texture; subsequent OpenGL calls will apply to this texture name.
    void bind() const nothrow{
        glBindTexture(TextureTarget.Texture2D, this.name);
    }
    /// Unbind this texture.
    void unbind() const nothrow{
        glBindTexture(TextureTarget.Texture2D, 0);
    }
    /// True if this texture's name is currently bound.
    @property bool bound() const{
        return Texture.boundname() == this.name;
    }
    /// Get the currently bound texture name.
    static Name boundname(){
        int name; // Texture names are uints but glGetIntegerv expects a signed int
        glGetIntegerv(GL_TEXTURE_BINDING_2D, &name);
        return cast(Name) name;
    }
    
    /// Set filter used when scaling the image.
    @property void filter(bool atomic = true)(in TextureFilter filter){
        mixin(AtomicMethodMixin);
        this.minfilter!false(cast(TextureMinFilter) filter);
        this.magfilter!false(cast(TextureMagFilter) filter);
    }
    /// Set filter used when scaling the image down.
    @property void minfilter(bool atomic = true)(in TextureMinFilter filter){
        mixin(AtomicMethodMixin);
        glTexParameteri(TextureTarget.Texture2D, TextureParam.MinFilter, filter);
    }
    /// Set filter used when scaling the image up.
    @property void magfilter(bool atomic = true)(in TextureMagFilter filter){
        mixin(AtomicMethodMixin);
        glTexParameteri(TextureTarget.Texture2D, TextureParam.MagFilter, filter);
    }
    
    /// Set how the texture wraps.
    @property void wrap(bool atomic = true)(in TextureWrap wrap){
        mixin(AtomicMethodMixin);
        glTexParameteri(TextureTarget.Texture2D, TextureParam.WrapS, wrap);
        glTexParameteri(TextureTarget.Texture2D, TextureParam.WrapT, wrap);
    }
    
    void mipmap(bool atomic = true)(){
        mixin(AtomicMethodMixin);
        // Doesn't work (Crashes because glGenerateMipmap isn't loaded)
        //glGenerateMipmapEXT(TextureTarget.Texture2D);
        // Not sure if this works or not honestly, but at least it doesn't crash
        glTexParameteri(TextureTarget.Texture2D, GL_GENERATE_MIPMAP, true);
    }
    
    @property Vector2!int size() const{
        return Vector2!int(this.width, this.height);
    }
    
    void update(bool atomic = true)(
        in Surface surface, in Vector2!int offset = Vector2!int.Zero
    ){
        FormattedSurface formatted = FormattedSurface.make!convert(surface);
        scope(exit) formatted.conclude();
        this.update(
            formatted.pixels, Box!int(offset, offset + formatted.size),
            formatted.format
        );
    }
    void update(bool atomic = true)(
        in void* pixels, Box!int box, PixelsFormat format = PixelsFormat.RGBA
    )in{
        assert(pixels, "Invalid pixel data.");
        assert((width > 0) & (height > 0), "Invalid texture size.");
        assert(box in Box!int(this.size), "Box not contained by texture bounds.");
    }body{
        mixin(AtomicMethodMixin);
        glTexSubImage2D(
            TextureTarget.Texture2D, 0,
            box.x, box.y, box.width, box.height,
            format, PixelsType.Ubyte, pixels
        );
    }
    
    /// Draw the texture at a position.
    void draw(N)(in N x, in N y) if(isNumeric!N){
        this.draw(Vector2!N(x, y));
    }
    /// ditto
    void draw(T)(in Vector2!T position){
        this.draw(Vertexesf.rect(position, this.size));
    }
    /// Draw a portion of a texture at a position.
    /// The subrect represents floating-point texture coords from 0.0 to 1.0.
    void draw(X, Y)(in Vector2!X position, in Box!Y sub){
        this.draw(Vertexesf.rect(position, sub.size * this.size, sub));
    }
    /// Draw the texture to a rectangular target.
    void draw(bool atomic = true, T)(in Box!T target){
        this.draw!atomic(Vertexesf.rect(target));
    }
    /// Draw a portion of the texture to a rectangular target.
    /// The subrect represents floating-point texture coords from 0.0 to 1.0.
    void draw(bool atomic = true, X, Y)(in Box!X target, in Box!Y sub){
        this.draw!atomic(Vertexesf.rect(target.topleft, target.size, sub));
    }
    void draw(bool atomic = true, A, B, C)(in Vertexes!(A, B, C) verts){
        mixin(AtomicMethodMixin);
        verts.setglpointers();
        glDrawArrays(GLPrimitive.TriangleStrip, 0, cast(uint) verts.length);
    }
    
    /// Draw a portion of the texture to a position.
    /// The subrect represents integral pixel coordinates on the texture.
    void drawsub(X, Y)(in Vector2!X position, in Box!Y sub){
        this.draw(position, Box!double(sub) / this.size);
    }
    /// Draw a portion of the texture to a rectangular target.
    /// The subrect represents integral pixel coordinates on the texture.
    void drawsub(X, Y)(in Box!X target, in Box!Y sub){
        this.draw(target, Box!double(sub) / this.size);
    }
}
